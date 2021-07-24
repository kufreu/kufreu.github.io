"""
land cover zonal statistics for chicago

kufre
"""

import rasterio as rio
import geopandas as gpd
import pandas as pd
from rasterstats import zonal_stats

raster = 'cookcountylandcover2010\landcover_2010_cookcounty.img'

# chicago tracts from chicago open data
with rio.open(raster) as src:
    chicago = gpd.read_file('https://data.cityofchicago.org/api/geospatial/5jrd-6zik?method=export&format=GeoJSON').to_crs(src.crs)

# reading dbf file for raster categories
dbf = gpd.read_file('cookcountylandcover2010\landcover_2010_cookcounty.img.vat.dbf')

# cleaning up categories
classes = [str(x).lower().replace('/','_').replace(' ','_') for x in dbf['Class']]

# creating dictionary to be used in zonal_stats()
land_cover = dict(zip(dbf['Value'].tolist(), classes))

zonal = zonal_stats(chicago.iloc[0:1],raster,categorical = True,nodata = 0, category_map = land_cover)

# blank DataFrame to be filled in with values from zonal_stats()
zeros = [0] * len(chicago)

results = pd.DataFrame(dict((v,zeros) for k,v in land_cover.items()))

results.insert(0,'geoid10', chicago['geoid10'])

# inserting values
for i in range(len(zonal)):
    row = zonal[i]
    for j in list(row.keys()):
        results.at[i,j] = row.get(j) * 4

chicago = chicago.merge(results, how = 'left', on = 'geoid10')

# calculating canopy percentage for each tract
chicago['pct_canopy'] = chicago['tree_canopy'] / chicago.area * 100

# save results
results.to_csv('chicago_land_cover.csv')

chicago.to_file('chicago.gpkg', layer ='land_cover', driver="GPKG")
