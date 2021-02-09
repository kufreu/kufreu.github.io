# comparing the method and data section in kang et al. to the provided code

### the methods
It can be seen when comparing the workflow in Figure 4 in [Kang et al.](https://ij-healthgeographics.biomedcentral.com/articles/10.1186/s12942-020-00229-x) for the enhanced two-step floating catchment area (E2SFCA) to the code provided in the [COVID-19 Accessibility Juptyer Notebook](https://cybergisxhub.cigi.illinois.edu/notebook/rapidly-measuring-spatial-accessibility-of-covid-19-healthcare-resources-a-case-study-of-illinois-usa/) that the code follows the workflow closely. I'll break up the pseudocode into its three main loops and have the equivalent Python code from the notebook to accompany it and compare it to.

#### finding the nearest node to the hospital:
pseudocode:
<pre>
<b>for</b> <i>hospital</i> in <i>hospitals</i> <b>do</b>
  Calculate node <i>n</i> in <i>road_network</i> closest to <i>hospital</i>
</pre>

Python:
``` python
def hospital_setting(hospitals, G):
    hospitals['nearest_osm']=None
    for i in tqdm(hospitals.index, desc="Find the nearest osm from hospitals", position=0):
        hospitals['nearest_osm'][i] = ox.get_nearest_node(G, [hospitals['Y'][i], hospitals['X'][i]], method='euclidean') # find the nearest node from hospital location
    print ('hospital setting is done')
    return(hospitals)
```

#### creating catchment areas:
pseudocode:
<pre>
<i>catchment</i> <-- []
<b>for</b> <i>hospital</i> in <i>hospitals</i> <b>do</b>
  <b>for</b> <i>driving_time</i> in [10,20,30] <b>do</b>
    <i>g</i> <-- ego-centric graph around <i>hospital</i> within <i>driving_time</i>
    <i>catchment</i> <-- calculate convex hull around nodes in <i>g</i>
    <i>catchment.population</i> <-- 0
    <b>for</b> <i>centroid</i> in <i>population_data</i> <b>do</b>
      <b>if</b> <i>centroid in population_data</i> <b>do</b>
        <i>catchment.population</i> += <i>centroid.population</i> x <i>weights[driving_time]</i>
        <i>catchment.time</i> <-- <i>driving_time</i>
</pre>

Python: <code> <b>for</b> <i>driving_time</i> in [10,20,30] <b>do</b> </code>

``` python
# get ego-centric graph around hospital around nodes in g and calculate convex hull around nodes in g
def calculate_catchment_area(G, nearest_osm, distance, distance_unit = "time"):
    road_network = nx.ego_graph(G, nearest_osm, distance, distance=distance_unit)
    nodes = [Point((data['x'], data['y'])) for node, data in road_network.nodes(data=True)]
    polygon = gpd.GeoSeries(nodes).unary_union.convex_hull ## to create convex hull
    polygon = gpd.GeoDataFrame(gpd.GeoSeries(polygon)) ## change polygon to geopandas
    polygon = polygon.rename(columns={0:'geometry'}).set_geometry('geometry')
    return polygon.copy(deep=True)
```

Python: <code> <b>for</b> <i>centroid</i> in <i>population_data</i> <b>do</b> </code>
- `calculate_catchment_area` used in this function
- Comments with four hashes show nested loop and if statement from pseudocode.

``` python
def hospital_measure_acc (_thread_id, hospital, pop_data, distances, weights):
    ##distance weight = 1, 0.68, 0.22
    polygons = []
    for distance in distances:
        polygons.append(calculate_catchment_area(G, hospital['nearest_osm'],distance))
    for i in range(1, len(distances)):
        polygons[i] = gpd.overlay(polygons[i], polygons[i-1], how="difference")

    num_pops = []
    #### for centroid in population_data do ####
    for j in pop_data.index:
        point = pop_data['geometry'][j]
        for k in range(len(polygons)):
            if len(polygons[i]) > 0: # to exclude the weirdo (convex hull is not polygon)
            #### if centroid in population_data do ####
                if (point.within(polygons[k].iloc[0]["geometry"])):
                    num_pops.append(pop_data['pop'][j]*weights[k])  
    total_pop = sum(num_pops)
    for i in range(len(distances)):
        polygons[i]['time']=distances[i]
        polygons[i]['total_pop']=total_pop
        polygons[i]['hospital_icu_beds'] = float(hospital['Adult ICU'])/polygons[i]['total_pop'] # proportion of # of beds over pops in 10 mins
        polygons[i]['hospital_vents'] = float(hospital['Total Vent'])/polygons[i]['total_pop'] # proportion of # of beds over pops in 10 mins
        polygons[i].crs = { 'init' : 'epsg:4326'}
        polygons[i] = polygons[i].to_crs({'init':'epsg:32616'})
    print('\rCatchment for hospital {:4.0f} complete'.format(_thread_id), end="")
    return(_thread_id, [ polygon.copy(deep=True) for polygon in polygons ])
```

#### overlapping hexagons with catchment areas
pseudocode:
<pre>
<i>result</i> { } // dictionary of hexagon IDs to accessibility
<b>for</b> <i>catchment</i> in <i>catchments</i> <b>do</b>
  <b>for</b> <i>hexagon</i> in <i>hexagons</i> <b>do</b>
    <i>overlap</i> <i>area(intesect(hexagon,catchment))/area(catchment)</i>
    <b>if</b> <i>overlap</i> &ge 0.5 <b>then</b>
      <i>result[hexagon.id]</i>+= <i>catchment.population X weights[catchment.time]</i>
<pre>

Python: for one grid cell
``` python
from collections import Counter
def overlap_calc(_id, poly, grid_file, weight, service_type):
  # calculates and aggregates accessibility statistics for one catchment on grid file
    value_dict = Counter()
    if type(poly.iloc[0][service_type])!=type(None):           
        value = float(poly[service_type])*weight
        intersect = gpd.overlay(grid_file, poly, how='intersection')
        intersect['overlapped']= intersect.area
        intersect['percent'] = intersect['overlapped']/intersect['area']
        intersect=intersect[intersect['percent']>=0.5]
        intersect_region = intersect['id']
        for intersect_id in intersect_region:
            try:
                value_dict[intersect_id] +=value
            except:
                value_dict[intersect_id] = value
    return(_id, value_dict)

def overlap_calc_unpacker(args):
    return overlap_calc(*args)
```

Python : for all grid cells, uses `overlap_calc`/`overlap_calc_unpacker`

``` python
def overlapping_function (grid_file, catchments, service_type, weights, num_proc = 4):
    grid_file[service_type]=0
    pool = mp.Pool(processes = num_proc)
    acc_list = []
    for i in range(len(catchments)):
        acc_list.extend([ catchments[i][j:j+1] for j in range(len(catchments[i])) ])
    acc_weights = []
    for i in range(len(catchments)):
        acc_weights.extend( [weights[i]]*len(catchments[i]) )
    results = pool.map(overlap_calc_unpacker, zip(range(len(acc_list)), acc_list, itertools.repeat(grid_file), acc_weights, itertools.repeat(service_type)))
    pool.close()
    results.sort()
    results = [ r[1] for r in results ]
    service_values = results[0]
    for result in results[1:]:
        service_values+=result
    for intersect_id, value in service_values.items():
        grid_file.loc[grid_file['id']==intersect_id, service_type] += value
    return(grid_file)
```

### the data and visualizations
Other than the image in Figure 3 that illustrates the creation of catchment areas shared, the research paper shares none of its figures with the Jupyter Notebook associated with the research. The notebook produces none of the maps or graphs present in the paper. And other than the network which is downloaded using OSMnx and prepared for analysis within the notebook, data collection and processing is mostly absent from the Jupyter Notebook. For example, it was mentioned in the paper that the 2018 American Community Survey 5-year detail table for Illinois' census tracts was obtained through an API, though neither this process nor the processing of this data was shown in the notebook. It was also noted in the paper that certain types of hospitals were excluded from the analysis but the filtering of the hospital dataset was not shown.
