feature_gen <- function(){
  
  # Aggregate review text by restaurant id
  review_text <- norm_data %>% select(review_id, text, stars) %>% filter(nchar(text) > 30)
  stop_words <- stopwords("SMART")
  #stop_words <- c("a", "the", "is", "and", "but", "or", "on", "it", "in", "i'm", "i", "of", "you", "your", "at", "an", "to", "was", "for", "with", "that", "my", "we", "this",
  #                "they", "had", "have", "were", "are", "so", "be", "as", "place", "im")
  # pre-processing:
  reviews <- gsub("'", "", review_text$text)  # remove apostrophes
  reviews <- gsub("[[:punct:]]", " ", reviews)  # replace punctuation with space
  reviews <- gsub("[[:cntrl:]]", " ", reviews)  # replace control characters with space
  reviews <- gsub("^[[:space:]]+", "", reviews) # remove whitespace at beginning of documents
  reviews <- gsub("[[:space:]]+$", "", reviews) # remove whitespace at end of documents
  reviews <- tolower(reviews)  # force to lowercase
  # tokenize on space and output as a list:
  doc.list <- strsplit(reviews, "[[:space:]]+")
  # compute the table of terms:
  term.table <- table(unlist(doc.list))
  term.table <- sort(term.table, decreasing = TRUE)
  # remove terms that are stop words or occur fewer than 5 times:
  del <- names(term.table) %in% stop_words | term.table < 5
  term.table <- term.table[!del]
  vocab <- names(term.table)
  # now put the documents into the format required by the lda package:
  get.terms <- function(x) {
    index <- match(x, vocab)
    index <- index[!is.na(index)]
    rbind(as.integer(index - 1), as.integer(rep(1, length(index))))
  }
  documents <- lapply(doc.list, get.terms)
  set.seed(200)
  k = 5
  params <- sample(c(-1, 1), k, replace=TRUE)
  t1 <- Sys.time()
  sldaOut <- slda.em(documents = documents, vocab =  vocab, K = k, num.e.iterations = 10, num.m.iterations = 10, variance = 0.25, 
                     alpha = 0.1, eta = 0.1, annotations = review_text$stars, params, lambda = 1.0, logistic = FALSE, method = "sLDA")
  t2 <- Sys.time()
  t2 - t1
  top_words <- top.topic.words(sldaOut$topics, num.words = 20)
  topic_coeff <- as.data.frame(sldaOut$coef)
  doc_sums <-  as.data.frame(t(sldaOut$document_sums)) %>% 
    mutate(total_words = (V1+V2+V3+V4+V5))
  topic_correlations <- cor(doc_sums)
  doc_sums$review_id <-  review_text$review_id
  doc_sums$text <- review_text$text

  sim_prep <-  norm_data %>% left_join(doc_sums, by = "review_id")
  sim_matrix_p <- sim_prep %>% 
    filter(positive == TRUE) %>% 
    group_by(user_id) %>% 
    summarise(tot_words = sum(total_words),
              P1 = sum(V1)/tot_words, P2 = sum(V2)/tot_words, P3 = sum(V3)/tot_words, P4 = sum(V4)/tot_words, P5 = sum(V5)/tot_words) %>% 
    select(-tot_words)
  sim_matrix_n <- sim_prep %>% 
    filter(positive == FALSE) %>% 
    group_by(user_id) %>% 
    summarise(tot_words = sum(total_words),
              N1 = sum(V1)/tot_words, N2 = sum(V2)/tot_words, N3 = sum(V3)/tot_words, N4 = sum(V4)/tot_words, N5 = sum(V5)/tot_words) %>% 
    select(-tot_words)
  sim_matrix <- sim_matrix_n %>% inner_join(sim_matrix_p, by = "user_id")
  sim_matrix <- sim_matrix %>% inner_join(price_t, by = "user_id")
  sim_matrix[is.na(sim_matrix)] <-  0

  sim_matrix
}