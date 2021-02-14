# week four: more on running the notebook locally
This week as winter term comes to a close, I was successful in running the [COVID-19 Accessibility Juptyer Notebook](https://cybergisxhub.cigi.illinois.edu/notebook/rapidly-measuring-spatial-accessibility-of-covid-19-healthcare-resources-a-case-study-of-illinois-usa/) on my Windows laptop. One issue which I encountered when running the notebook both on CyberGISX and on my laptop was that the code cell where the catchment areas where created would run indefinitely. Although the same problem was blocking my progress, they had different causes. I found the cause of the problem on my laptop to be the combination of using [multiprocessing in a Jupyter Notebook on Windows](https://medium.com/@grvsinghal/speed-up-your-python-code-using-multiprocessing-on-windows-and-jupyter-or-ipython-2714b49d6fac). The fix to this problem was a simple one: I just needed to save the functions that would be run in parallel in a separate .py file and import them to the notebook. In addition to doing this, I made some small changes to the functions creating catchment areas based on what I learned in my [last post](week_04_pt2.md). I made changes to the loop in `hospital_measure_acc` calling `calculate_catchment_area` to incorporate `single_source_dijkstra_path_length` and `subgraph`.

```python
polygons = []
sorted_dist = sorted(distances, reverse = True)

g_dict = nx.single_source_dijkstra_path_length(network, hospital['nearest_osm'], sorted_dist[0], distance_unit)
g = network.subgraph(g_dict)

for distance in sorted_dist:
    if distance == max(distances):
        polygons.append(create_catchment_area(g))
    else:
        g_dict = {key: value for (key, value) in g_dict.items() if value <= distance}
        g = g.subgraph(g_dict)
        polygons.append(create_catchment_area(g))
polygons.reverse()
```
After the list `polygons` is created, the list distances is sorted so that largest value is in the first position. Using this distance, a dictionary of nodes in the network within this distance is created and this dictionary is used to make a subgraph of the network. The if-else statement in the following loop is straightforward: if distance is the largest value in the list, create a catchment area from the subgraph and add it to the empty list, otherwise create a new dictionary of nodes within a certain distance and make a subgraph of the preexisting subgraph. The list of distances is sorted in descending order in order to do this. The resulting list of polygons is then reversed to match the results of the original loop. The function `create_catchment_area` is just an altered version of `calculate_catchment_area` that takes a graph as an argument.

```python
def create_catchment_area(g):
    nodes = [Point((data['x'], data['y'])) for node, data in g.nodes(data=True)]
    polygon = gpd.GeoSeries(nodes).unary_union.convex_hull ## to create convex hull
    polygon = gpd.GeoDataFrame(gpd.GeoSeries(polygon)) ## change polygon to geopandas
    polygon = polygon.rename(columns={0:'geometry'}).set_geometry('geometry')
    return polygon.copy(deep=True)
```
