# Yelp Recommender System From Review Text

Text mining project originally developed for Text Mining (INLS 613) at UNC - Chapel Hill

Goal is to predict new restaurant ratings from previous user review text on Yelp. Uses 
Latent Dirichlet Allocation to find topic distributions for each review and then creates 
aggregated user level topic distributions. These topic distributions are then used as 
features in k-Nearest neighbor algorithm to predict new user/restaurant pairs.

The analysis is written in R and Yelp data can be obtained from the [Yelp Dataset Challenge](https://www.yelp.com/dataset_challenge).
Full analysis can be run from main_analysis.R which calls other files for each step of the analysis process.


## Description

### main_analysis.R
* Calls each of the subprograms below to run the full analysis from reading in data to evaluating predictions.

### data_read.R
1. Reads in business and review JSON files
2. Flattens to dataframes
3. Filters to desired list of restaurants
4. Merges together restaurants and reviews

### train_test.R
1. Normalizes review rating on user-by-user basis
2. Splits dataset into training and test sets

### features.R
1. Performs pre-processing of review text (punctuation and stopword removal, lower case, etc.)
2. Converts to data layout expected by Supervised Latent Dirichlet Allocation (SLDA) function
3. Runs SLDA to generate topic distributions for each review
4. Aggregates each user's topic distribution over all of their reviews and outputs as feature matrix

### predict.R
1. Custom kNN algorithm that considers all neighbors weighted by their correlation
2. Predicts review rating from weighted average of neighbors

