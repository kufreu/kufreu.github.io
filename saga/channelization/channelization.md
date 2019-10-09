# saga
### hydrology analysis of kilimanjaro
SAGA was used in this project to derive channel networks and other terrain products from global elevation models obtained from NASA’s Shuttle Radar Topography Mission. Shown below are the steps taken to process the data. Zip files with tool outputs can also be found on this page. 

#### opening data in saga
![adding data](images/addingData.png)
#### creating a mosaic using mosaicking tool and reprojecting in utm
![mosaic](images/mosaic.PNG)
#### making a hillshade from mosaic for visualization
![hillshade](images/hillshade.PNG)
#### finding sink routes in mosaic using sink drainage route dectection tool
![sink route](images/sinkRoute.PNG)
##### close-up image
![sink route close-up](images/sinkRouteClose.png)
#### removing sinks from mosaic using sink removal tool
![no sinks](images/mosaicNoSinks.PNG)
#### flow accumulation (top-down)
![flow accumulation](images/flowAccumulation.PNG)
#### using flow accumulation to create a channel network
![channel network](images/channelNetwork.PNG)
##### close-up of channel network in black
![channel network black](images/channelNetworkClose.png)
##### channel network overlaid on mosaic
![channel netowork on mosaic](images/mosaicChannel.PNG)
##### hillshade and channel network
![hillshade network](images/hillshadeChannelNetwork.png)

### data source
NASA JPL. NASA Shuttle Radar Topography Mission Global 1 arc second. 2013, distributed by NASA EOSDIS Land Processes DAAC, [https://doi.org/10.5067/MEaSUREs/SRTM/SRTMGL1.003]( https://doi.org/10.5067/MEaSUREs/SRTM/SRTMGL1.003)

### data (.sgrid)
[SRTM tiles](data/rawData.zip)

[mosaic projected in UTM](data/mosaicUTM.zip)

[analytical hillshade](data/hillshade.zip)

[sink route detection](data/sinkRoute.zip)

[mosaic with sinks removed](data/mosaicNoSinks.zip)

[flow accumulation](data/flowAccumulation.zip)

[channel network (.sgrid and shapefile)](data/channelNetwork.zip)

