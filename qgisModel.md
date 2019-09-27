# qgis models
### about
to be completed ~~25.09.2019~~ 26.09.2019 (hopefully)

### how the models work and shortcomings
#### original model
![original model](distDir.PNG)
![distance]
![direction](direction.PNG)
![cardinal](cardOrd.PNG)
#### sql version
![SQL model](distDirSQL.PNG)

![SQL in model](SQL.PNG)

This model differs from the original with its use of the Execute SQL tool to calculate distance. Input1 is the city center while input2 are the input features seen in the model above. Using 'true' in the query results in distance being calculated in meters rather than degrees. Both features are transformed to WGS 1984, the World Geodetic System 1984, to ensure that distance is accurately calculated and to prevent errors which may arise from using the CRS of the input features. Despite Mean Coordinates not being used to calculate distance, it is kept in this model solely because the direction calculation would not function without it. For whatever reason I was unable to use the input from City Center to calculate direction, so the model still creates a centroid an inputted point and uses the mean coordinates of the centroid to create a point which can be used in the calculation. Although it is redundant, it works. The calculation for cardinal and ordinal direction remained the same. 

### models
~~[calculates distance and direction from a point](distDirFromPoint.model3)~~ **broken**

[this improved and *functional* version partially uses sql and calculates distance and direction from a point](qgisModelSQL.md)

### mapped outputs
![distance calculated for wayne county, michigan](wayneDistMI.png)
![direction calculated for wayne county, michigan](wayneDirMI.png)

### graphs made using outputs of models

[direction of tracts from detroit cbd in wayne county and percentage white](pctWhiteWayne.html)

[direction of tracts from detroit cbd in wayne county and percentage black](pctBlackWayne.html)

[distance (m) of tracts from detroit cbd in wayne county and median gross rent](medianGrossRentWayne.html)

### data
[census tracts for michigan with outputs for kent, washtenaw, and wayne counties](censusMI.gpkg)

[qgis project file](censusMI.qgz)
