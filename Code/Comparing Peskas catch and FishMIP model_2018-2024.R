#-----------------------
#Code to compare FishMIP model outputs with Peskas catch data (2018-2024) to investigate relative change
#-----------------------

#-----------------------
# Load packages
#-----------------------

# Load necessary packages
library(tidyverse)  # For data manipulation and visualization
library(lubridate)  # For date handling

#-----------------------
# Load data and check
#-----------------------

# Read the FishMIP data
fishmip_data <- read_csv("/Users/louwclaassens/Documents/Documents - Louw’s MacBook Air/WorldFish/Ikan Ba Futura_2023/Science and colabs/Ecological Modeling/Timor-Leste South Coast/Timor_South_Ecopath/Timor_Ecopath/Data/Raw data/Biological/FISHMIP_mean_ensemble_perc_change_fish_bio_timeseries_timor-leste_1950-2100.csv")

# Read the PESKAS catch data
peskas_data <- read_csv("/Users/louwclaassens/Documents/Documents - Louw’s MacBook Air/WorldFish/Ikan Ba Futura_2023/Science and colabs/Ecological Modeling/Timor-Leste South Coast/Timor_South_Ecopath/Timor_Ecopath/Data/Raw data/Fisheries/PESKAS_timor_catch_2018_mar2025.csv")

# Examine the structure of both datasets
glimpse(fishmip_data)
glimpse(peskas_data)

#-----------------------
# Process Peskas data
#-----------------------

# Correctly parse the date in Day, Month, Year format
# First check the format of a few date entries
head(peskas_data$date_bin_start)

# Parse date using dmy() for Day, Month, Year format
peskas_data <- peskas_data %>%
  mutate(date = dmy(date_bin_start),
         year = year(date))

# Check if the years were extracted correctly
table(peskas_data$year)

peskas_data <- peskas_data %>%
  filter(year >=2018, year <=2024)

# Aggregate catch by year (sum across all regions and species)
annual_catch <- peskas_data %>%
  group_by(year) %>%
  summarise(total_catch_kg = sum(estimated_catch_kg, na.rm = TRUE)) %>%
  ungroup()

# Calculate percent change relative to first year (2018)
baseline_catch <- annual_catch %>% 
  filter(year == 2018) %>% 
  pull(total_catch_kg)

annual_catch <- annual_catch %>%
  mutate(percent_change = (total_catch_kg / baseline_catch * 100) - 100)


#-----------------------
# Filter FishMIP data
#-----------------------

# Filter FishMIP data for the years that overlap with PESKAS data (2018-2024)
# Also filter for a specific scenario if needed (adjust as necessary)
fishmip_subset <- fishmip_data %>%
  filter(year >= 2018, year <= 2024)

# If there are multiple scenarios, you might want to separate them
fishmip_scenarios <- fishmip_subset %>%
  split(.$scenario)

#-----------------------
# Visualise comparison
#-----------------------

# Basic comparison plot of relative changes
ggplot() +
  # Add FishMIP model range (min to max)
  geom_ribbon(data = fishmip_subset, 
              aes(x = year, ymin = min_change, ymax = max_change),
              alpha = 0.2, fill = "blue") +
  # Add FishMIP mean trend line
  geom_line(data = fishmip_subset, 
            aes(x = year, y = mean_change, color = "FishMIP Projection")) +
  # Add PESKAS observed data
  geom_line(data = annual_catch, 
            aes(x = year, y = percent_change, color = "PESKAS Observed Catch")) +
  geom_point(data = annual_catch,
             aes(x = year, y = percent_change), color = "red", size = 3) +
  # Improve plot appearance
  labs(title = "Comparison of Projected vs. Observed Changes in Timor-Leste Fisheries",
       subtitle = "Relative change compared to 2018 baseline",
       y = "Percent Change (%)", 
       x = "Year", 
       color = "Data Source") +
  theme_minimal() +
  scale_color_manual(values = c("FishMIP Projection" = "blue", 
                                "PESKAS Observed Catch" = "red"))

#-----------------------
# Correlation
#-----------------------

# Calculate correlation - make sure to include min_change and max_change
comparison_data <- fishmip_subset %>%
  select(year, mean_change, min_change, max_change) %>%
  inner_join(annual_catch %>% select(year, percent_change), by = "year")

# Calculate correlation
correlation <- cor(comparison_data$mean_change, comparison_data$percent_change, 
                   method = "spearman", use = "complete.obs")

# Print correlation
print(paste("Spearman correlation between FishMIP projections and PESKAS catch trends:", 
            round(correlation, 3)))

#-----------------------
# Comparison table
#-----------------------

# Now create the comparison table
comparison_table <- comparison_data %>%
  mutate(difference = percent_change - mean_change,
         within_range = percent_change >= min_change & percent_change <= max_change) %>%
  select(year, FishMIP = mean_change, PESKAS = percent_change, 
         difference, within_range)

print(comparison_table)
