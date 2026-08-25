### STRATEGIC ANALYSIS OF THE MUSIC MARKET ###

# Author: Francisco Rezzonico

# Last revised on: August 25, 2026

# Description:
# This script conducts exploratory data analysis (EDA) of Spotify tracks
# released from 2020–2023 to examine patterns associated with song popularity.
# It produces univariate visualizations and descriptive statistics for numeric
# and categorical variables, bivariate analyses of duration, speechiness, genre,
# artist experience, and popularity, and trivariate analyses of duration and
# speechiness across genre and popularity groups. The results support subsequent
# modeling and interpretation for potential diversification and investment
# opportunities for Tainy Records.

# -----------------------------------------------------------------------------#

# Libraries.
library(dplyr)
library(flextable)
library(ggplot2)
library(plotly)
library(psych)
library(summarytools)

# Apply consistent formatting to descriptive-statistics tables.
set_flextable_defaults(
  font.family = 'Times New Roman',
  font.size = 11,
  font.color = 'black',
  border.color = 'black',
  background.color = 'white',
  padding = 2.75,
  line_spacing = 1.3,
  decimal.mark = '.',
  big.mark = ','
)

# Load the cleaned Spotify dataset.
spotify_db <- read.csv('data/clean_spotify_data.csv')


# UNIVARIATE ANALYSIS

# Examine the distribution of speechiness values across songs.
hist(
  spotify_db$speechiness,
  col = '#bcbd22',
  main = "Distribution of the Proportion of Spoken Words in the Song",
  xlab = "Speechiness",
  cex.main = 1.8,
  cex.lab = 1.3,
  cex.axis = 1.1
)

# Examine the distribution of song duration in seconds.
hist(
  spotify_db$duration_s,
  col = '#17becf',
  main = "Distribution of the Duration of the Song (in Seconds)",
  xlab = "Seconds",
  cex.main = 1.8,
  cex.lab = 1.3,
  cex.axis = 1.1
)

# Display frequency distributions for the selected categorical variables.
freq(spotify_db[, c(3, 7, 10)])

# Calculate selected descriptive statistics for duration and speechiness.
quant_descriptives <- spotify_db %>%
  select(duration_s, speechiness) %>%
  descr(transpose = TRUE) %>%
  as.data.frame() %>%
  select(N, Min, Max, Median, Mean, Std.Dev, Skewness) %>%
  round(2) %>%
  rownames_to_column(var = "Variable") %>%
  mutate(
    Variable = recode(
      Variable,
      duration_s = "Duration (in seconds)",
      speechiness = "Speechiness"
    )
  )

# Present the descriptive-statistics table in the report format.
quant_descriptives %>%
  flextable() %>%
  autofit()


# BIVARIATE ANALYSIS

## Duration vs Genre

# Compare song-duration distributions by genre, with and without outliers.
par(mfrow = c(1, 2))

bp_1 <- boxplot(
  spotify_db$duration_s ~ spotify_db$genre,
  xlab = "Genre",
  ylab = "Seconds",
  names = c("Dance", "Hip-Hop", "House", "Indie-Pop", "Pop"),
  main = "Duration of Songs (in seconds) By Genre",
  col = c('#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd'),
  cex.main = 1.8,
  cex.lab = 1.3,
  cex.axis = 1.1
)

bp_2 <- boxplot(
  spotify_db$duration_s ~ spotify_db$genre,
  outline = FALSE,
  xlab = "Genre",
  ylab = "Seconds",
  names = c("Dance", "Hip-Hop", "House", "Indie-Pop", "Pop"),
  main = "Duration of Songs (in seconds) By Genre (Outliers Removed)",
  col = c('#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd'),
  cex.main = 1.8,
  cex.lab = 1.3,
  cex.axis = 1.1
)


## Speechiness vs Genre

# Summarize speechiness within each genre to compare central tendency and spread.
tapply(spotify_db$speechiness, spotify_db$genre, summary)


## Artists vs Popularity

# Count songs for each artist group within each popularity category.
artist_popularity_counts <- spotify_db %>%
  count(artists_factor, popularity_factor, name = "Count")

# Compare popularity-group counts across artist groups.
artist_popularity_counts %>%
  plot_ly(
    x = ~artists_factor,
    y = ~Count,
    color = ~popularity_factor,
    type = "bar",
    colors = c("#1F77B4", "#FF7F0E")
  ) %>%
  layout(
    title = "Song Popularity by Artist Group",
    xaxis = list(title = "Artist Group"),
    yaxis = list(title = "Number of Songs", standoff = 20),
    barmode = "group",
    margin = list(
      l = 100,
      r = 40,
      b = 100,
      t = 80,
      pad = 5
    )
  )


## Duration vs Speechiness

# Estimate and test the linear correlation between duration and speechiness.
cor_d_s <- cor.test(spotify_db$duration_s, spotify_db$speechiness)
cor_d_s

# Visualize the relationship and fitted linear trend between duration and
# speechiness.
ggplot(spotify_db, aes(x = duration_s, y = speechiness)) +
  geom_point(alpha = 0.2, color = "black") +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  labs(
    title = "Speechiness Vs Duration",
    x = "Song Duration (Seconds)",
    y = "Speechiness",
    caption = paste0(
      "Correlation: ",
      round(cor_d_s$estimate, 3)
    )
  ) +
  coord_cartesian(
    xlim = c(0, 800),
    ylim = c(0, 1),
    expand = FALSE
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10))
  )


## Song Duration vs. Popularity

# Compare song-duration distributions between popularity groups.
boxplot(
  spotify_db$duration_s ~ spotify_db$popularity_factor,
  xlab = "Popularity Group",
  ylab = "Seconds",
  names = c("Least Popular", "Most Popular"),
  main = "Duration of Songs (in Seconds) by Popularity Group",
  col = c("#1f77b4", "#ff7f0e"),
  cex.main = 1.8,
  cex.lab = 1.3,
  cex.axis = 1.1
)


## Genre vs. Popularity

# Calculate within-genre popularity shares before plotting the composition.
spotify_db %>%
  count(genre, popularity_factor) %>%
  group_by(genre) %>%
  mutate(Percentage = n / sum(n)) %>%
  ungroup() %>%
  mutate(
    genre = str_to_title(genre)
  ) %>%
  plot_ly(
    x = ~genre,
    y = ~Percentage,
    color = ~popularity_factor,
    type = "bar",
    colors = c("#1F77B4", "#FF7F0E")
  ) %>%
  layout(
    title = "Song Popularity by Genre",
    xaxis = list(title = "Genre"),
    yaxis = list(title = "Percentage of Songs", tickformat = ".0%"),
    barmode = "stack"
  )


# TRIVARIATE ANALYSIS

## Speechiness vs Genre vs Popularity

# Compare speechiness distributions by genre and popularity category.
ggplot(spotify_db, aes(x = genre, y = speechiness, fill = popularity_factor)) +
  geom_boxplot() +
  labs(
    title = "Speechiness by Genre and Popularity",
    x = "Genre",
    y = "Speechiness",
    fill = "Popularity"
  ) +
  scale_fill_manual(
    values = c(
      "Least Popular" = "#1f77b4",
      "Most Popular" = "#ff7f0e"
    )
  ) +
  scale_x_discrete(
    labels = tools::toTitleCase
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )
