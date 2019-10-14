# comparing aster & srtm data for andes mountains 
Here I looked at the reference data for the study area using NUM (number of scenes) files for ASTER and SRTM data and compared the outputs of the hydrology analysis using ASTER and SRTM data. Possible sources for error and uncertainty in the original datasets and if/how these things propagate through the analysis were also examined.  

### visualizations of .num files
#### aster
![aster .num](images/numASTER.png)
![aster legend](images/numASTER_legend.png)

The reference data for ASTER much of the data for this region came solely from the ASTER GDEM V3, which is the third version of the ASTER global digital elevation model. There are areas dispersed across the region which were either interpolated or came from SRTM. The individual tiles can still be seen after being mosaicked because data along the tile borders were obtained from the USGS National Elevation Dataset (NED), SRTM, and other sources.

#### srtm
![srtm .num](images/numSRTM.png)
![srtm legend](images/numSRTM_legend.png)

A considerable amount of data in the Andes came ASTER, much more than data ASTER used from SRTM. The data for the valleys on other side of the mountain range were obtained from the shuttle mission. 

### difference between aster and srtm elevation data
![difference](images/diffASTER_SRTM.png)
![difference legend](images/diffASTER_SRTM_legend.png)

### channel network difference 
![channel networks](images/channels.png)

### files 
[diffrence .sgrd](data/diffASTER_SRTM.zip)

[qgis project file and shapefiles](data/channelNetworks.zip)

#### num files in .sgrd with .sprm (for classifications)
[ASTER](data/numASTER.zip)

[SRTM](data/numSRTM.zip)



