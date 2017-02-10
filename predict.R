filter_kNN <- function(user, business, k){
  # Find other users who have rated this restaurant
  filtered <- norm_data %>% 
    filter(business_id == business) %>% 
    select(user_id, norm_stars)
  # Add active user to list
  filtered2 <- rbind(filtered, c(user, "NA"))
  # Filter similarity matrix to users who have rated this restaurant
  sim_filter <- sim_matrix %>% inner_join(filtered2, by = "user_id") %>% select(-norm_stars)
  # Transpose data frame and move active user to 2nd column
  sim_t <- dcast(melt(sim_filter), ...~user_id, fun.aggregate=mean)
  sim_t <- sim_t %>% select(variable, get(user), everything())
  dist <-  NULL
  user_id <-  NULL
  for(i in 1:(ncol(sim_t)-2)) {
    dist[i] <- as.numeric(cor(sim_t[,2], sim_t[,i+2]))
    user_id[i] <- as.character(names(sim_t)[i+2])
  } 
  # Sort k nearest neighbors
  #sorted <- arrange(as.data.frame(cbind(dist, user_id)), desc(dist))[1:k,] %>% mutate(weight = 1 + (1 - row_number())*(1/k))
  sorted <- arrange(as.data.frame(cbind(dist, user_id)), desc(dist)) %>% filter(!is.na(dist))
  if (length(sorted$dist) == 0) {
    avg <- filtered %>% filter(user_id != user)  %>% 
      summarise(predict = mean(as.numeric(norm_stars)))
    avg %>% mutate(user_id = user, business_id = business)
  } else {
    #Assign active user the average rating of K-NN
    avg <- filtered %>% filter(user_id != user) %>% 
      inner_join(sorted, by ="user_id")  %>%
      summarise(predict = sum(as.numeric(dist)*as.numeric(norm_stars))/sum(as.numeric(dist)))
    avg %>% mutate(user_id = user, business_id = business)
    #avg <- filtered %>% filter(user_id != user) %>% 
    #  inner_join(sorted, by ="user_id")  %>% 
    #  summarise(predict = sum(as.numeric(weight)*as.numeric(norm_stars))/sum(as.numeric(weight)))
    #avg %>% mutate(user_id = user, business_id = business)
  }
}  

predict_fun <- function(norm_data, sim_matrix, test_norm_data, seed){
  set.seed(seed)
  # Draw balanced sample to test predictions
  positive_sample <- sample(which(test_norm_data$positive == "TRUE"), size = 750, replace = F)
  negative_sample <- sample(which(test_norm_data$positive == "FALSE"), size = 750, replace = F)
  test <- test_norm_data[c(positive_sample, negative_sample),]
  test <- test %>% 
    select(user_id, business_id, stars, norm_stars, user_avg, user_sd, positive)
  predictions  <-  data.frame(user_id = character(), business_id = character(), predict = numeric())
  predictions2  <-  data.frame(user_id = character(), business_id = character(), predict = numeric())
  # Turn off warnings temporarily
  oldw <- getOption("warn")
  options(warn = -1)
  # Run kNN and save in predictions dataframe
  for (i in 1:length(test$user_id)) {
    predictions <- rbind(predictions, filter_kNN(as.character(test[i,1]), as.character(test[i,2]), 5))
  }
  check <- test
  check$predict <- predictions$predict
  # Calculate accuracy statistics
  check <- check %>% 
    mutate(correct_norm = (positive == (predict > 0)),
           predict_unnorm = (predict*user_sd + user_avg),
           stars_bin = (stars >= 4),
           sq_diff = ((stars - predict_unnorm)^2),
           diff = (stars - predict_unnorm),
           abs_diff = ((abs(stars - predict_unnorm))),
           user_predict = ((user_avg >= 4) == stars_bin),
           user_sq_diff = (user_avg - stars)^2,
           user_abs_diff = (abs((user_avg - stars)))
    )
  
  options(warn = oldw)
  check
}


