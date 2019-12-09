#search geographic twitter data for Hurricane Dorian, by Joseph Holler, 2019
#to search, you first need a twitter API token: https://rtweet.info/articles/auth.html 

#install package for twitter and initialize the library
install.packages("rtweet")
library(rtweet)


############# SEARCH TWITTER API ############# 

#set up twitter API information
#this should launch a web browser and ask you to log in to twitter
#replace app, consumer_key, and consumer_secret data with your own developer acct info
twitter_token <- create_token(
  app = "yourapp",  					#replace yourapp with your app name
  consumer_key = "yourkey",  		#replace yourkey with your consumer key
  consumer_secret = "yoursecret",  #replace yoursecret with your consumer secret
  access_token = NULL,
  access_secret = NULL
)

#get tweets for hurricane Dorian, searched on September 11, 2019
dorian <- search_tweets("dorian OR hurricane OR sharpiegate", n=200000, include_rts=FALSE, token=twitter_token, geocode="32,-78,1000mi", retryonratelimit=TRUE)


#get tweets without any text filter for the same geographic region in November, searched on November 19, 2019
#the query searches for all verified or unverified tweets, so essentially everything
november <- search_tweets("-filter:verified OR filter:verified", n=200000, include_rts=FALSE, token=twitter_token, geocode="32,-78,1000mi", retryonratelimit=TRUE)

############# FIND ONLY PRECISE GEOGRAPHIES ############# 

#convert GPS coordinates into lat and lng columns
dorian <- lat_lng(dorian,coords=c("coords_coords"))
november <- lat_lng(november,coords=c("coords_coords"))

#select any tweets with lat and lng columns (from GPS) or designated place types of your choosing
dorian <- subset(dorian, place_type == 'city'| place_type == 'neighborhood'| place_type == 'poi' | !is.na(lat))
november <- subset(november, place_type == 'city'| place_type == 'neighborhood'| place_type == 'poi' | !is.na(lat))

#convert bounding boxes into centroids for lat and lng columns
dorian <- lat_lng(dorian,coords=c("bbox_coords"))
november <- lat_lng(november,coords=c("bbox_coords"))



