# week four: using a faster method to create catchment areas
Throughout this winter term, I have run into problems running the [COVID-19 Accessibility Juptyer Notebook](https://cybergisxhub.cigi.illinois.edu/notebook/rapidly-measuring-spatial-accessibility-of-covid-19-healthcare-resources-a-case-study-of-illinois-usa/) in CyberGISX. After only recently being able to run the code preparing the data for the model, I ran into another roadblock: creating the catchment areas. Earlier this week, the cell where the catchments were calculated ran for two days with no sign of stopping. I spent part of this week working to improve the performance of this section of the notebook and began looking at how the catchments are calculated after receiving an insightful email from Professor Holler.     

``` python
def calculate_catchment_area(G, nearest_osm, distance, distance_unit = "time"):
    road_network = nx.ego_graph(G, nearest_osm, distance, distance=distance_unit)
    nodes = [Point((data['x'], data['y'])) for node, data in road_network.nodes(data=True)]
    polygon = gpd.GeoSeries(nodes).unary_union.convex_hull ## to create convex hull
    polygon = gpd.GeoDataFrame(gpd.GeoSeries(polygon)) ## change polygon to geopandas
    polygon = polygon.rename(columns={0:'geometry'}).set_geometry('geometry')
    return polygon.copy(deep=True)
```
He found that the culprit for the slow running times in `calculate_catchment_area` is its use of the function `ego_graph`.

```python
road_network = nx.ego_graph(G, nearest_osm, distance, distance=distance_unit)
```
With each iteration that `calculate_catchment_area` is called and `ego_graph` is used within it, a subset of an existing graph is created, which was rather time consuming.
Professor Holler proposed using `single_source_dijkstra_path_length` and `subgraph` as a replacement.

```python
road_network = G.subgraph(nx.single_source_dijkstra_path_length(G, nearest_osm, distance, distance_unit))  
```
First, `single_source_dijkrtra` returns a dictionary of identifiers for the nodes that compose the shortest paths from a given node. This dictionary of node identifiers is then used in `subgraph` to create a view of a larger graph, in our case the road network of Illinois, rather than creating a new graph with its own attributes as is done in `ego_graph`. I've put together a short [notebook](https://github.com/kufreu/kufreu.github.io/blob/master/geog0700/ego_dijkstra.ipynb) that demonstrates the time saved when replacing `ego_graph` with a combination of `single_source_dijkstra_path_length` and `subgraph` in `calculate_catchment_area` and that the results are equivalent to when `ego_graph` is used. For example, creating a catchment area using the latter, shown in the notebook as `dijkstra_cca`, took 880 milliseconds while the original function (`ego_cca`) took 4.67 seconds.
