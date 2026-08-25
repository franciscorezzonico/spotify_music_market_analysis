### STRATEGIC ANALYSIS OF THE MUSIC MARKET ###

# Author: Francisco Rezzonico

# Last revised on: August 19, 2026

# Description:
# This script performs data wrangling and preparation for Spotify tracks
# released from 2020–2023. It cleans, transforms, and structures variables
# related to genre, duration, speechiness, artist experience, and song
# popularity for subsequent analysis of potential diversification and investment
#  opportunities for Tainy Records.

# -----------------------------------------------------------------------------#

# Libraries.
library(tidyverse)

# Import the dataset.
file_path <- file.choose()
spotify_db <- read.csv(file_path)

# Select the variables that will be used and filter the dataset.
spotify_db <- spotify_db %>%
  filter(year > 2019) %>%
  select(artist_name, popularity, genre, speechiness, duration_ms)

# Create a new variable for the duration of the song in seconds.
spotify_db$duration_s <- spotify_db$duration_ms / 1000

# Drop categories in the "genre" variable to only include the top 5 most popular
# genres.
genres_pop_df <- spotify_db %>%
  group_by(genre) %>%
  summarise(
    mean_popularity = mean(popularity, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  slice_max(mean_popularity, n = 5, with_ties = TRUE)

spotify_db <- spotify_db %>%
  filter(genre %in% genres_pop_df$genre)

# Create a factor variable for popularity.
spotify_db$popularity_factor <- ifelse(
  spotify_db$popularity >= quantile(spotify_db$popularity, 0.75, na.rm = T),
  "Most Popular",
  "Least Popular"
) %>%
  as.factor()

# Add the number of songs per artist, then create categorical and factor
# variables indicating whether each artist has more, fewer, or the average
# number of songs.
mean_n_songs <- spotify_db %>%
  count(artist_name) %>%
  summarise(mean_n_songs = mean(n)) %>%
  pull(mean_n_songs)

spotify_db <- spotify_db %>%
  add_count(artist_name, name = "n_songs") %>%
  mutate(
    avg_songs = case_when(
      n_songs > mean_n_songs ~ "More songs than average",
      n_songs < mean_n_songs ~ "Fewer songs than average",
      TRUE ~ "An average number of songs"
    ),
    artists_factor = factor(
      paste("Artist with", str_to_lower(avg_songs))
    )
  )

# Create a new variable that stores the number of songs each artist has.
spotify_db <- spotify_db %>%
  add_count(artist_name, name = "n_songs")

# Export the "spotify_db" dataset as a .csv file.
write.csv(spotify_db, 'data/clean_spotify_data.csv', row.names = FALSE)
