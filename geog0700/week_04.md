# comparing the method and data section in kang et al. to the provided code
<<<<<<< HEAD
=======
It can be seen when comparing the workflow in Figure 4 in [Kang et al.](https://ij-healthgeographics.biomedcentral.com/articles/10.1186/s12942-020-00229-x) for the enhanced two-step floating catchment area (E2SFCA) to the code provided in the [COVID-19 Accessibility Juptyer Notebook](https://cybergisxhub.cigi.illinois.edu/notebook/rapidly-measuring-spatial-accessibility-of-covid-19-healthcare-resources-a-case-study-of-illinois-usa/) that the code follows the workflow closely In the first
```
for `*`hospital`*` in `*`hospitals`*` <bold>do`**`
  Calculate node *n* in *road_network* closest to *hospital*
```
>>>>>>> 2827cb58d2aaa7cf6749147754b3e6952a758aa1

<pre>
for hospital in *hospitals*  **do**
  Calculate node *n* in *road_network* closest to *hospital*
</pre>
<<<<<<< HEAD
=======

Other than the image in Figure 3 that illustrates the creation of catchment areas shared, the research paper shares none of its figures with the Jupyter Notebook associated with the research. The notebook produces none of the maps or graphs present in the paper. And other than the network which is downloaded using OSMnx and prepared for analysis within the notebook, data collection and processing is mostly absent from the Jupyter Notebook. For example, it was mentioned in the paper that the 2018 American Community Survey 5-year detail table for Illinois' census tracts was obtained through an API, though neither this process nor the processing of this data was shown in the notebook. It was also noted in the paper that certain types of hospitals were excluded from the analysis but the filtering of the hospital dataset was not shown.
>>>>>>> 2827cb58d2aaa7cf6749147754b3e6952a758aa1
