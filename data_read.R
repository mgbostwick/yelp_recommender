read_in <- function(business, review, states, category){

  library(dplyr)
  library(jsonlite)
  library(tidyr)
  library(stringr)
  
  #Read in JSON data and output as R tables
  business_data <- stream_in(file(business))
  business_flat <- flatten(business_data)
  business_tbl <- as_data_frame(business_flat)
  save(business_tbl, file = "business_tbl.Rda")
  
  review_data <- stream_in(file(review))
  review_flat <- flatten(review_data)
  review_tbl <- as_data_frame(review_flat)
  save(review_tbl, file = "review_tbl.Rda")
  
  #1.filter business dataset to restaurants in US cities
  #2.join restaurant list to review dataset, only keeping US restaurants
  #3.combine reviews at the user level
  #4.combine reviews at restaurant level
  
  restaurants <- business_tbl %>% 
    filter(str_detect(categories, category)) %>% 
    filter(state %in% states) %>% 
    select(business_id, state, categories, review_count, `attributes.Price Range`)
  reviews_fltr <- review_tbl %>% inner_join(restaurants, by ="business_id")
  save(reviews_fltr, file = "reviews_fltr.Rda")

}