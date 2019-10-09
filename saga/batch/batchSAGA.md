# batch scripting in saga
### about
I used batch processing for tools in SAGA to automate the hydrology analysis done on Mount Kilimanjaro. ASTER global elevation models of the Andes Mountains east of Santiago were chosen as an alternative study region for this analysis. Both the batch file and the inputs for the script can be found on this page.
### script
```bat
:: hydrology analysis script
:: created by kufre u.

:: this script automates a hydrology analysis in SAGA using .sgrd or .hgt files with elevation data
:: files used in analysis should be placed in folder with batch script in order to run
:: tools can be skipped using two colons (::)
:: non-essential tool parameters can be added, deleted, and or edited

::set the path to your SAGA program
SET PATH=%PATH%;c:\saga6

::set the prefix to use for all names and outputs
SET pre=andesASTER

::set the directory in which you want the outputs to be saved, example directory shown here
SET od=W:\GIScience\hydrologyAnalysis\%pre%

::this creates the output directory if it doesn't exist already
if not exist %od% mkdir %od%

:: Run Mosaicking tool, with consideration for the inputs -GRIDS and -RESAMPLING
saga_cmd grid_tools 3 -GRIDS=ASTGTMV003_S34W070_dem.sgrd;ASTGTMV003_S34W071_dem.sgrd;ASTGTMV003_S35W070_dem.sgrd;ASTGTMV003_S35W071_dem.sgrd -NAME=%pre%Mosaic -TYPE=9 -RESAMPLING=0 -OVERLAP=1 -MATCH=0 -TARGET_OUT_GRID=%od%\%pre%mosaic.sgrd

:: Run UTM Projection
saga_cmd pj_proj4 24 -SOURCE=%od%\%pre%mosaic.sgrd -RESAMPLING=1 -KEEP_TYPE=1 -GRID=%od%\%pre%mosaicUTM.sgrd -UTM_ZONE=19 -UTM_SOUTH=1

:: Run Sink Drainage Route Detection
saga_cmd ta_preprocessor 1 -ELEVATION=%od%\%pre%mosaicUTM.sgrd -SINKROUTE=%od%\%pre%sinkRoute.sgrd -THRESHOLD=0 -THRSHEIGHT=100

::Run Sink Removal
saga_cmd ta_preprocessor 2 -DEM=%od%\%pre%mosaicUTM.sgrd -SINKROUTE=%od%\%pre%sinkRoute.sgrd -DEM_PREPROC=%od%\%pre%mosaicNoSinks.sgrd -METHOD=1 -THRSHEIGHT=100

:: Run Analytical Hillshade
saga_cmd ta_lighting 0 -ELEVATION=%od%\%pre%mosaicNoSinks.sgrd -SHADE=%od%\%pre%Hillshade.sgrd -METHOD:0 -POSITION=0 -AZIMUTH=315 -DECLINATION=45 -EXAGGERATION=1 -UNIT=0

:: Run Flow Accumulation (Top-Down)
saga_cmd ta_hydrology 0 -ELEVATION=%od%\%pre%mosaicNoSinks.sgrd -SINKROUTE=%od%\%pre%sinkRoute.sgrd -FLOW=%od%\%pre%flowAccumulation.sgrd -STEP=1 -FLOW_UNIT=0 -METHOD=4 -LINEAR_DO=1 -LINEAR_MIN=500

:: Run Channel Network
saga_cmd ta_channels 0 -ELEVATION=%od%\%pre%mosaicNoSinks.sgrd -INIT_GRID=%od%\%pre%flowAccumulation.sgrd -CHNLNTWRK=%od%\%pre%ChannelNetwork.sgrd -SHAPES=%od%\%pre%ChannelNetwork.shp -INIT_METHOD=2 -INIT_VALUE=1000 -MINLEN=10

:: Print a message
ECHO completed.
PAUSE
```
[batch file](hydrologyAnalysis.bat)
### data source
NASA/METI/AIST/Japan Spacesystems, and U.S./Japan ASTER Science Team. ASTER Global Digital Elevation Model V003. 2019, distributed by NASA EOSDIS Land Processes DAAC, [https://doi.org/10.5067/ASTER/ASTGTM.003](https://doi.org/10.5067/ASTER/ASTGTM.0030). 
 
### input data of andes mountains
[ASTER DEMs in .sgrid](andesASTER.zip)

