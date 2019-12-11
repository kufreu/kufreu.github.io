# analysis of tweets during hurricane dorian using r and postgis 
### about
RStudio, QGIS, and GeoDa were used in this lab to analyze tweets to see if either a glaringly doctored hurricane map (SharpieGate) or the actual path of Hurricane Dorian drove more Twitter activity. 

### textual analysis of tweets
[This script](code/dorianTwitterScript.R) was written by Professor Holler and was used to search and download the geographic Twitter data used in this lab using R. This script resulted in two data frames: dorian, which contains tweets about Hurricane Dorian, and november, which contains tweets with no text filter that were made in the same geographic region as the tweets. The dates when the tweets were searched can be found on the script. The status IDs for these tweets can be found [here](data/november.csv) and [here](data/dorian.csv).

After this was done, further preperations were made to analyze the tweets. 
It was first necessary to install these packages and load them into RStudio.
```r
install.packages(c("rtweet","dplyr","tidytext","tm","tidyr","ggraph", "ggplot2"))
```
The text of each  tweets was first selected from the data frames and then words from the text.
```r
dorianText <- select(dorian,text)
novemberText <- select(november,text)

dorianWords <- unnest_tokens(dorianText, word, text)
novemberWords <- unnest_tokens(novemberText, word, text)
```
The stop words were then removed from these objects through these steps.
```r
data("stop_words")
stop_words <- stop_words %>% add_row(word="t.co",lexicon = "SMART")

dorianWords <- dorianWords %>%
  anti_join(stop_words) 

novemberWords <- novemberWords %>%
  anti_join(stop_words)
```
I then graphed the count of the unique words used in the tweets using ggplot2 having removed the useless words. 
```r
dorianWords %>%
  count(word, sort = TRUE) %>%
  top_n(15) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(x = word, y = n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip() +
  labs(x = "Count",
       y = "Unique words",
       title = "Count of unique words")
```
![dorian words](images/dorianWords.png)
Excluding https, which should be added to the list of stop words, hurricane and dorian unsurpsingly appear the most in tweets. Alabama, the focus of SharpieGate, lags behind these two, though was still used more than what brought about its increased use. Word pairs were then made and graphed using ggraph. 
```r
#### creating word pairs ####
dorianWordPairs <- dorian %>% select(text) %>%
  mutate(text = removeWords(text, stop_words$word)) %>%
  unnest_tokens(paired_words, text, token = "ngrams", n = 2)

novemberWordPairs <- november %>% select(text) %>%
  mutate(text = removeWords(text, stop_words$word)) %>%
  unnest_tokens(paired_words, text, token = "ngrams", n = 2)

dorianWordPairs <- separate(dorianWordPairs, paired_words, c("word1", "word2"),sep=" ")
dorianWordPairs <- dorianWordPairs %>% count(word1, word2, sort=TRUE)

novemberWordPairs <- separate(novemberWordPairs, paired_words, c("word1", "word2"),sep=" ")
novemberWordPairs <- novemberWordPairs %>% count(word1, word2, sort=TRUE)

#### graphing word cloud with space indicating association ####
dorianWordPairs %>%
  filter(n >= 30) %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  # geom_edge_link(aes(edge_alpha = n, edge_width = n)) +
  # hurricane and dorian occur the most together
  geom_node_point(color = "darkslategray4", size = 3) +
  geom_node_text(aes(label = name), vjust = 1.8, size = 3) +
  labs(title = "Dorian Tweets",
       subtitle = "September 2019 - Text mining twitter data ",
       x = "", y = "") +
  theme_void()
```
![dorian cloud](images/dorianCloud.png)

The complete script for this analysis can be found [here](code/textual.R).

### uploading data to postgis database and continuing analysis 
After using R and RStudio to conduct a texual analysis of the tweets, the tweets and downloaded counties with census estimates were uploaded to my PostGIS database using [this script](code/postgis.R). The counties were obtained from the Census using a function from TidyCensus.
```r
Counties <- get_estimates("county",product="population",output="wide",geometry=TRUE,keep_geo_vars=TRUE, key="woot")
```

![heatmap](images/heatmap.png)

![ndti](images/tweets.png)


### spatial statistics with geoda 
After all this was done, I opened GeoDa, connected to my database and loaded the counties table into the program. 
![geoda](images/countiesGetisOrdMapFrame.png)
![geoda2](images/countiesSigGetisOrdMapFrame.png)

