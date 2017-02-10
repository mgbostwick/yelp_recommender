# Wayfair code sample

Text mining project originally developed for Text Mining (INLS 613) at UNC - Chapel Hill

Goal is to predict new restaurant ratings from previous user review text on Yelp. Uses Latent Dirichlet Allocation to find topic distributions for each review and then creates aggregated user level topic distributions. These topic distributions are then used as features in k-Nearest neighbor algorithm to predict new user/restaurant pairs.

Full analysis can be run from main_analysis.R which calls other files for each step of the analysis process.
