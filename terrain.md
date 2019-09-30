# saga
### terrain analysis of kilimanjaro
Data: NASA JPL. NASA Shuttle Radar Topography Mission Global 1 arc second. 2013, distributed by NASA EOSDIS Land Processes DAAC, [https://doi.org/10.5067/MEaSUREs/SRTM/SRTMGL1.003]( https://doi.org/10.5067/MEaSUREs/SRTM/SRTMGL1.003)

#### opening data in saga
![adding data](addingData.png)
#### creating a mosaic using mosaicking tool and reprojecting in utm
![mosaic](mosaic.PNG)
#### making a hillshade from mosaic for visualization
![hillshade](hillshade.PNG)
#### finding sink routes in mosaic using sink drainage route dectection tool
![sink route](sinkRoute.PNG)
##### close-up image
![sink route close-up](sinkRouteClose.png)
#### removing sinks from mosaic using sink removal tool
![no sinks](mosaicNoSinks.PNG)
#### flow accumulation (top-down)
![flow accumulation](flowAccumulation.PNG)
#### using flow accumulation to create a channel network
![channel network](channelNetwork.PNG)
##### close-up of channel network in black
![channel network black](channelNetworkClose.png)
##### channel network overlaid on mosaic
![channel netowork on mosaic](mosaicChannel.PNG)

