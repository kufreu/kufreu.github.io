"""
land cover zonal statistics for chicago

kufre
"""

import rasterio as rio
import geopandas as gpd
import pandas as pd
from rasterstats import zonal_stats

raster = 'cookcountylandcover2010\landcover_2010_cookcounty.img'

# get raster resolution and crs
with rio.open(raster) as src:
    state_plane = src.crs

# chicago tracts from chicago open data
chicago = gpd.read_file('https://data.cityofchicago.org/api/geospatial/5jrd-6zik?method=export&format=GeoJSON').to_crs(state_plane)

# reading dbf file for raster categories
dbf = gpd.read_file('cookcountylandcover2010\landcover_2010_cookcounty.img.vat.dbf')

classification = dbf['Class']

# cleaning up categories
classification = [str(x).lower().replace('/','_').replace(' ','_') for x in classification]

values =  dbf['Value'].tolist()

# creating dictionary to be used in zonal_stats()
landcover = dict(zip(values,classification))

zonal = zonal_stats(chicago,raster,categorical = True,nodata = 0, category_map = landcover)

zeros = [0] * len(chicago)

# blank DataFrame to be filled in with values from zonal_stats()
results = pd.DataFrame(dict((v,zeros) for k,v in landcover.items()))

results.insert(0,'geoid10', chicago['geoid10'])

# inserting values
for i in range(len(zonal)):
    row = zonal[i]
    for j in list(row.keys()):
        results.at[i,j] = row.get(j) * 4

chicago = chicago.merge(results, how = 'left', on = 'geoid10')

# calculating canopy percentage for each tract
chicago['pct_canopy'] = chicago['tree_canopy'] / chicago.area * 100

results.to_csv('chicago_land_cover.csv')

chicago.to_file('chicago.gpkg', layer ='land_cover', driver="GPKG")
