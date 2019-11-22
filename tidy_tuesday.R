library(data.table)
library(ggplot2)
nz_bird <- fread("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-11-19/nz_bird.csv", 
                 na.strings = "NA")
nz_bird[, vote_rank := as.numeric(gsub("vote_", "", nz_bird[, vote_rank]))]
ls <- nz_bird[vote_rank == 1, 
              .(sum = sum(vote_rank)), 
              by = c("bird_breed")][order(-sum)][1:10]$bird_breed
ls <- factor(ls, levels = ls, ordered = T)
nz_bird[vote_rank == 1, .(sum = sum(vote_rank)), by = c("bird_breed")][order(-sum)][1:10] %>%
  ggplot(aes(x = factor(bird_breed, levels = sort(ls, decreasing = T)), y = sum, fill = bird_breed)) + 
  geom_col() + coord_flip() + theme(legend.position = "none") + 
  scale_fill_manual(values = rep(c("#2BFF9F", "#41E83A", "#D2FF4D", "#EBD12D", "#FFB31F"),2)) +
  labs(title = "Highly Ranked Birds") + xlab("Bird Breed") + ylab("Number of Times Ranked #1") 

