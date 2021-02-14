# week two: attempting to reproduce kang et al.
I spent this week looking through the Jupyter Notebook provided by [Kang et al.](https://github.com/cybergis/COVID-19AccessibilityNotebook) and trying to reproduce their research on the [CyberGISX](https://cybergisxhub.cigi.illinois.edu/) platform. Although a straightforward task, working with the notebook this week quickly became a troublesome waiting game. The first issue I encountered and one which I entered the week knowing was that the Jupyter notebook was unable to download a large file used in the analysis. The notebook would fail after hours of attempting to download the file. The R script from [last week](week_01.md) was written in part to solve this problem, downloading the GraphML file of Illinois' street network used in the analysis as well as other data. However, I did not take into account the version of [osmnx](https://github.com/gboeing/osmnx) I used to download the network and this seemed to lead more problems. The GraphML file written with a more recent version of osmnx could not be read by version of the package on CyberGISX used in the notebook. I thought using a different file format could solve this problem, so I went on to save the network as a geopackage and then try to create a graph from GeoDataFrames, though this did not seem to work either. We then decided to update the osmnx package and this allowed for the GraphML file to be read. However, running the model in the analysis using Illinois was still somewhat unfeasible. It took a good amount of time to run the first code cell of the model where the GraphML was loaded and then the next code cell where catchments were created ran indefinitely. I tried running the notebook on my laptop rather than on CyberGISX and saw some improvement, with the first cell taking only four minutes to run rather than 22, though I left the notebook to run for hours after this with no success.

Reproducing and replicating the research of Kang et al. is feasible to a point. If this research was to be reproduced/replicated in a course, the area of interest used in the analysis should be limited to a certain size. Running the model on large graphs is time-consuming and inefficient. Derrick demonstrated [here]( https://derrickburt.github.io/opengis/ctCovid/ctCovid.html) that this research can be replicated using Connecticut, a state whose area is around 10% that of Illinois, and aptly documents other shortcomings replicating the study such as data availability.  When replicating and reproducing this research,  data collection and preparation can be done within the notebook. For example, much of the data can be read using a URL and the steps taken to prepare the data can easily be done in Python and documented.

``` python
# this is a limited example of reading the data
import pandas as pd
import geopandas as gpd

covid_cases = pd.read_csv('https://idph.illinois.gov/DPHPublicInformation/api/COVIDExport/GetZip?format=csv')
hospitals = gpd.read_file('https://opendata.arcgis.com/datasets/6ac5e325468c4cb9b905f1728d6fbf0f_0.geojson')
icu  = gpd.read_file('https://opendata.arcgis.com/datasets/6ac5e325468c4cb9b905f1728d6fbf0f_0.geojson')
```
Census data can be obtained using a package like [census](https://github.com/datamade/census) or directly through the Census Bureau's API. It may be best to review the tutorials provided by CyberGISX for working with spatial data in Python and Python basics before going this route, however. Although I am currently unable to import QGIS in CyberGISX, it may also be possible to create the hexagonal grid used in the research in a notebook. Alternatively, data collection and preparation can be done using [R](week_01.md).

## more on running the notebook locally
I had a little bit more success running the Jupyter Notebook locally on my laptop, so I will go through the steps of working with the notebook outside of CyberGISX. The whole process is rather straightforward. The first step is to download the [GitHub repository](https://github.com/cybergis/COVID-19AccessibilityNotebook) for the research. If not done already, either [Anaconda](https://www.anaconda.com/products/individual) or [Miniconda](https://docs.conda.io/en/latest/miniconda.html) should be installed. In my case I am using Miniconda. The next step after downloading the notebook and installing Anaconda/Miniconda is to open the Anaconda Prompt and create a new environment for the project. I thought it would be appropriate to name the environment I am working in `illinois`.  

```shell
conda create -n illinois python=3.8
```
After this is done, the new environment should be activated to work within it.

```shell
conda activate illinois
```
With the new environment being created and activated, what comes next is to install the necessary packages. The repository contains a requirements.txt file which specifies what python packages are required to run notebook. This file can be used to install the required packages.

```shell
conda install --file requirements.txt
```

I did not do this here but the full file path of requirements.txt needs to be used. Although not listed in requirments.txt as being required packages, it is necessary to also install `jupyter-lab` to be able to work with Jupyter notebooks and ipywidgets to work with this specific notebook.

```shell
conda install ipywidgets jupyterlab
```
To open JupyterLab and work with the Jupyter notebook in a browser, you just need to type the name of the package. The environment JupyterLab is installed needs to be activated first before using the package.

```shell
jupyter-lab
```

Unlike on CyberGISX, I was able to download the GraphML file for Illinois within the Jupyter notebook, though it took a good amount of time to do so. Though as I said earlier, I was still unable to completely run the model on my laptop.
