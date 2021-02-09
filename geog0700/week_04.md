# comparing the method and data section in kang et al. to the provided code

<pre>
for <i>hospital</i> in <i>hospitals</i>  <b>do</b>
  Calculate node <i>n</i> in <i>road_network</i> closest to <i>hospital</i>
</pre>

Other than the image in Figure 3 that illustrates the creation of catchment areas shared, the research paper shares none of its figures with the Jupyter Notebook associated with the research. The notebook produces none of the maps or graphs present in the paper. And other than the network which is downloaded using OSMnx and prepared for analysis within the notebook, data collection and processing is mostly absent from the Jupyter Notebook. For example, it was mentioned in the paper that the 2018 American Community Survey 5-year detail table for Illinois' census tracts was obtained through an API, though neither this process nor the processing of this data was shown in the notebook. It was also noted in the paper that certain types of hospitals were excluded from the analysis but the filtering of the hospital dataset was not shown.
