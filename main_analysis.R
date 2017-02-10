setwd("/Users/michaelbostwick/repos/wayfair_code")
source("data_read.R")

# Read in JSON files and create merged dataframe
states <- c("AZ", "NC", "NV", "PA", "WI", "IL") #States to include
read_in("~/Documents/INLS_613/yelp_dataset/yelp_academic_dataset_business.json", 
        "~/Documents/INLS_613/yelp_dataset/yelp_academic_dataset_review.json",
        states, "Restaurant")

state_filter <- "WI"
min_review <- 20 # Minimum number of reviews per restaurant
year_split <- 2016 # First year of test set

# Create training and test data sets
source("train_test.R")

# Generates features using supervised LDA and outputs user similarity matrix. This function can be modified to calculate
# user similarity in alternative ways as long as the result is a matrix with users in the rows and similarity features in the columns.
source("features.R")
features <- feature_gen()

# Generate predictions on test data set
source("predict.R")
eval <- predict_fun(norm_data, features, test_norm_data, seed = 5)

# Evaluate accuracy of model
(baseline_norm <- sum(eval$positive) / length(eval$correct_norm)) # Baseline: random guessing
(accuracy_norm <- sum(eval$correct_norm) / length(eval$correct_norm)) # overall model accuracy
(positive_acc <- sum(eval$correct_norm & eval$positive) / sum(eval$positive == TRUE)) # accuracy on positive ratings
(negative_acc <- sum(eval$correct_norm & eval$positive == FALSE) / sum(eval$positive == FALSE)) # accuracy on negative ratings
(mean(eval$user_sq_diff)) # Mean squared error
(mean(eval$user_abs_diff)) # Mean absolute error