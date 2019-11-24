
# Setup -------------------------------------------------------------------

library(data.table)
library(ggplot2)
library(viridis)
library(plotly)
library(gridExtra)
options(scipen = 15)
setwd("~/Desktop/RWorkspace/stats_of_doom/tidytuesday")

####Sources####
#data gathered from
#https://media.tri-rail.com/Files/About/Resources/Ridership/2019/05MAY2019board_mtg_ver.pdf
#and
#https://media.tri-rail.com/Files/About/SFRTA/Planning/Reports/2018%20On-Board%20Survey%20-%20Final%20Report_083018%20-%20w_Appendices.pdf


# Data Wrangling ----------------------------------------------------------

#read in data
dt <- fread("tabula-05MAY2019board_mtg_ver.csv", header = T)
#fix header
names(dt) <- as.character(dt[1,])
#take out what I don't want
dt <- dt[-c(51:52),]
#remove NA column
dt[, "NA" := NULL]
#remove first row
dt <- dt[-1,]
#fix values by keeping text
Station <- apply(dt[,1], 1, function(x) gsub('\\d','', x))
Station <- gsub(',','', Station)
#fix values of other col by numbers 
On <- apply(dt[,1], 1, function(x) gsub('\\D','', x))
#new data.table with vars I'm interested in 
nw <- data.table(Station, On)
#tidy: remove dt
rm(dt)
#new data.table for totals
g_totals <- data.table(tail(nw, 4))
#take out totals
nw <- nw[-c(74:77),]
#assign val with rows with nothing in the "On" column
nms <- as.character(nw[On == "",]$Station)
#repeat them so I can create a var of it and it can match rest of table
nms <- rep(nms[-13], each = 3)
#check length
length(nms)
#take out rows with nothing in the "On" column
nw <- (na.omit(nw[On != "",]))
#assign new station column
nw[, Station := data.table(gsub(" Totals ", "", as.character(nw$Station)))]
#rename columns
names(nw) <- c("Days", "Totals")
#column bind two data.tables
trains <- cbind(Station = nms, nw)
#tidy: remove nw
rm(nw)
#transform totals to numeric
trains[, Totals := as.numeric(trains$Totals)]
#fix totals table
names(g_totals) <- c("Totals","Count") 
#transform count to numeric
g_totals[, Count := as.numeric(Count)]

#read in "on time" data
time <- fread("tabula-2018 On-Board Survey - Final Report_083018 - w_Appendices.csv", header = F)
#fix headers
names(time) <- c("Description","Valid Responses","% of Total Respondents")
#take out `%` and transform percentage to numeric
time[, `% of Total Respondents` := as.numeric(gsub("%", "", time$`% of Total Respondents`))]

#prepare for donut chart
g_totals$fraction <- g_totals$Count / sum(g_totals$Count)
g_totals[-4,]

# Compute the cumulative percentages (top of each rectangle)
g_totals$ymax <- cumsum(g_totals$fraction)
g_totals

# Compute the bottom of each rectangle
g_totals$ymin <- c(0, head(g_totals$ymax, n=-1))
g_totals
# Compute label position
g_totals$labelPosition <- (g_totals$ymax + g_totals$ymin) / 2

# Compute a good label
g_totals$label <- paste0(g_totals$Totals, "\n value: ", g_totals$Count)
g_totals


# Visualization -------------------------------------------------------------------
p1 <- trains %>%
  ggplot(aes(x = Station, y = Totals)) + 
  geom_col(aes(fill = Days), alpha = .8) +
  coord_flip() + labs(title = "Tri-Rail Riders in the Month of May, 2019", 
                      subtitle = "Stations by Time of Week") +
  scale_fill_manual(values = rep(c("#FFFE5A", "#2EFFA4", "#213CFF"),length(unique(trains$Station))))

p2 <- ggplot(g_totals[-4,], aes(ymax=ymax, ymin=ymin, xmax=3, xmin=1, fill=Totals)) +
  geom_rect() +
  geom_text( x=4, aes(y=labelPosition, label=label, color=Totals), size=4) + 
  # x here controls label position (inner / outer)
  scale_fill_brewer(palette=3) +
  scale_color_brewer(palette=3) +
  coord_polar(theta="y") +
  xlim(c(-1, 4)) +
  ggtitle("Total Ridership", subtitle = "Month of May, 2019") +
  theme_void() +
  theme(legend.position = "none", plot.title = element_text(hjust = .5), 
        plot.subtitle = element_text(hjust = .5))

p3 <- time %>% ggplot(aes(x = factor(Description, levels = Description, ordered = T), 
                          y = `Valid Responses`, alpha = `% of Total Respondents`)) + 
  scale_color_viridis() +
  geom_col() + ggtitle("Train Timeliness") +
  theme(plot.title = element_text(hjust = .5)) +
  labs(x = "Description", caption = "Based on 2018 survey report.") 

grid.arrange(p1, p2, p3, layout_matrix = rbind(c(1,1), c(2,3)))