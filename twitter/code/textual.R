#### textual analysis of dorian twitter data ####
# script adapted from an analysis made by Dr. Joseph Holler

install.packages(c("rtweet","dplyr","tidytext","tm","tidyr","ggraph", "ggplot2"))

library(rtweet)
library(dplyr)
library(tidytext)
library(tm)
library(tidyr)
library(ggraph)
library(ggplot2)


count(dorian, place_type)

#### getting text from tweets ####
dorianText <- select(dorian,text)
novemberText <- select(november,text)

dorianWords <- unnest_tokens(dorianText, word, text)
novemberWords <- unnest_tokens(novemberText, word, text)


#### counting all words ####
count(dorianWords)
count(novemberWords)

##### creating a list of stop words and adding "t.co" twitter links to the list ####
data("stop_words")
stop_words <- stop_words %>% add_row(word="t.co",lexicon = "SMART")

dorianWords <- dorianWords %>%
  anti_join(stop_words) 


novemberWords <- novemberWords %>%
  anti_join(stop_words) 


##### graphing count of unique words ####
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

novemberWords %>%
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

#graphing word cloud with space indicating association
dorianWordPairs %>%
  filter(n >= 30) %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  # geom_edge_link(aes(edge_alpha = n, edge_width = n)) +
  # hurricane and dorian occur the most together
  geom_node_point(color = "darkslategray4", size = 3) +
  geom_node_text(aes(label = name), vjust = 1.8, size = 3) +
  labs(title = "Dorian Tweets",
       subtitle = "August 2019 - Text mining twitter data ",
       x = "", y = "") +
  theme_void()


novemberWordPairs %>%
  filter(n >= 15) %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  # geom_edge_link(aes(edge_alpha = n, edge_width = n)) +
  # link and bio 
  geom_node_point(color = "darkslategray4", size = 3) +
  geom_node_text(aes(label = name), vjust = 1.8, size = 3) +
  labs(title = "November Tweets",
       subtitle = "November 2019 - Text mining twitter data ",
       x = "", y = "") +
  theme_void()
