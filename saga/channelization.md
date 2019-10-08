# saga
### channelization analysis of kilimanjaro
SAGA was used in this project to derive channel networks and other terrain products from global elevation models obtained from NASA’s Shuttle Radar Topography Mission. Shown below are the steps taken to process the data.

[unalterted data](channelization/data/rawData)

#### opening data in saga
![adding data](channelization/images/addingData.png)
#### creating a mosaic using mosaicking tool and reprojecting in utm
![mosaic](channelization/images/mosaic.PNG)
#### making a hillshade from mosaic for visualization
![hillshade](channelization/images/hillshade.PNG)
#### finding sink routes in mosaic using sink drainage route dectection tool
![sink route](channelization/images/sinkRoute.PNG)
##### close-up image
![sink route close-up](channelization/images/sinkRouteClose.png)
#### removing sinks from mosaic using sink removal tool
![no sinks](channelization/images/mosaicNoSinks.PNG)
#### flow accumulation (top-down)
![flow accumulation](channelization/images/flowAccumulation.PNG)
#### using flow accumulation to create a channel network
![channel network](channelization/images/channelNetwork.PNG)
##### close-up of channel network in black
![channel network black](channelization/images/channelNetworkClose.png)
##### channel network overlaid on mosaic
![channel netowork on mosaic](channelization/images/mosaicChannel.PNG)
##### hillshade and channel network
![hillshade network](channelization/images/hillshadeChannelNetwork.png)
