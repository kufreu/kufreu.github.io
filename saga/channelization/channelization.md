# saga
### channelization analysis of kilimanjaro
SAGA was used in this project to derive channel networks and other terrain products from global elevation models obtained from NASA’s Shuttle Radar Topography Mission. Shown below are the steps taken to process the data. Zip files can also be found on this page. 

#### opening data in saga
![adding data](saga/channelization/images/addingData.png)
#### creating a mosaic using mosaicking tool and reprojecting in utm
![mosaic](saga/channelization/images/mosaic.PNG)
#### making a hillshade from mosaic for visualization
![hillshade](saga/channelization/images/hillshade.PNG)
#### finding sink routes in mosaic using sink drainage route dectection tool
![sink route](saga/channelization/images/sinkRoute.PNG)
##### close-up image
![sink route close-up](saga/channelization/images/sinkRouteClose.png)
#### removing sinks from mosaic using sink removal tool
![no sinks](saga/channelization/images/mosaicNoSinks.PNG)
#### flow accumulation (top-down)
![flow accumulation](saga/channelization/images/flowAccumulation.PNG)
#### using flow accumulation to create a channel network
![channel network](saga/channelization/images/channelNetwork.PNG)
##### close-up of channel network in black
![channel network black](saga/channelization/images/channelNetworkClose.png)
##### channel network overlaid on mosaic
![channel netowork on mosaic](saga/channelization/images/mosaicChannel.PNG)
##### hillshade and channel network
![hillshade network](saga/channelization/images/hillshadeChannelNetwork.png)

### data source
NASA JPL. NASA Shuttle Radar Topography Mission Global 1 arc second. 2013, distributed by NASA EOSDIS Land Processes DAAC, [https://doi.org/10.5067/MEaSUREs/SRTM/SRTMGL1.003]( https://doi.org/10.5067/MEaSUREs/SRTM/SRTMGL1.003)

### data (.sgrid)
[SRTM tiles](channelization/data/rawData.zip)

[mosaic projected in UTM](channelization/data/mosaicUTM.zip)

[analytical hillshade](channelization/data/hillshade.zip)

[sink route detection](channelization/data/sinkRoute.zip)

[mosaic with sinks removed](channelization/data/mosaicNoSinks.zip)

[flow accumulation](channelization/data/flowAccumulation.zip)

[channel network (in .sgrid and shapfile)](channelization/data/channelNetwork.zip)

