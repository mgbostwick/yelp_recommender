library(reshape2)
library(dplyr)
library(tidyr)
library(stringr)
library(tm)
library(lda)
library(weights)
library(lsa)

state_rest <- reviews_fltr %>% 
  filter(state == state_filter) %>% 
  filter(review_count > min_review) %>% 
  mutate(year = str_sub(date, 1, 4))
base_data <- state_rest %>% 
  filter(year > 2009 & year < year_split) %>% 
  mutate(price = `attributes.Price Range`) %>% 
  select(-`attributes.Price Range`)
test_data <- state_rest %>% 
  filter(year >= year_split)

user_stats <- base_data %>% 
  group_by(user_id) %>% 
  summarise(user_avg = mean(stars),
            user_sd = sd(stars),
            user_count = n()
  )
base_data <- base_data %>% inner_join(user_stats, by = "user_id") 
test_data <- test_data %>% inner_join(user_stats, by = "user_id")

# Normalize star ratings by user avg rating and standard deviation
# Remove user's with standard deviation = 0 (users with only 1 review, or no variation in reviews)
norm_data <- base_data %>% 
  mutate(norm_stars = ((stars - user_avg) / user_sd)) %>% 
  filter(user_sd > 0) %>% 
  mutate(positive = (norm_stars >= 0))
user_price_stats <- norm_data %>% 
  group_by(user_id, price) %>% 
  summarise(price_rating = mean(positive))
price_t <- dcast(user_price_stats, user_id~price, fun.aggregate=mean)[,1:5]
names(price_t) <-  c("user_id", "Price1", "Price2", "Price3", "Price4")
price_t[is.na(price_t)] <-  0
rest_stats <- norm_data %>% 
  group_by(business_id) %>% 
  summarise(rest_count = n())
test_data <- test_data %>% inner_join(rest_stats, by = "business_id")
test_norm_data <- test_data %>% 
  mutate(norm_stars = ((stars - user_avg) / user_sd)) %>% 
  filter(user_sd > 0) %>% 
  mutate(positive = (norm_stars >= 0))