## ============================================================================
## Timor-Leste South Coast Species Data Analysis
## ============================================================================
# This script imports the updated species list and sets up a framework
# for sourcing additional data on these species.

# Load required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,    # For data manipulation and visualization
  readxl,       # For reading Excel files
  rfishbase,    # For accessing FishBase data
  worrms,       # For World Register of Marine Species data
  obistools,    # For OBIS tools
  mapdata,      # For map data
  sf,           # For spatial data manipulation
  leaflet,      # For interactive maps
  robis,        # For Ocean Biogeographic Information System
  taxize        # For taxonomic information
)

# Set working directory (update this to your project folder)
# setwd("~/path/to/your/project")
working_dir <- "/Users/louwclaassens/Documents/Documents - Louw’s MacBook Air/WorldFish/Ikan Ba Futura_2023/Science and colabs/Ecological Modeling/Timor-Leste South Coast/Timor_South_Ecopath/Timor_Ecopath/Data"
setwd(working_dir)

# Import the updated species list
species_list <- read.delim("updated-species-list.txt", 
                           stringsAsFactors = FALSE, 
                           sep = "\t")

# Basic data inspection
glimpse(species_list)
summary(species_list)

# Fix any issues with the species list
species_list <- species_list %>%
  # Remove any empty rows
  filter(!is.na(Genus) & Genus != "") %>%
  # Standardize binomial names (remove extra spaces)
  mutate(Binomial = trimws(Binomial),
         # Create a clean scientific name column
         scientific_name = str_replace_all(Binomial, "\\s+", " "),
         # Extract family from Peskas_Group where possible
         family = case_when(
           Peskas_Group == "Snappers and seaperches" ~ "Lutjanidae",
           Peskas_Group == "Groupers" ~ "Serranidae",
           Peskas_Group == "Emperors" ~ "Lethrinidae",
           Peskas_Group == "Parrotfishes" ~ "Scaridae",
           Peskas_Group == "Surgeonfishes" ~ "Acanthuridae",
           Peskas_Group == "Rabbitfishes" ~ "Siganidae",
           Peskas_Group == "Damselfishes" ~ "Pomacentridae",
           Peskas_Group == "Wrasses" ~ "Labridae",
           Peskas_Group == "Butterflyfishes" ~ "Chaetodontidae",
           Peskas_Group == "Triggerfishes" ~ "Balistidae",
           Peskas_Group == "Jacks and trevallies" ~ "Carangidae",
           Peskas_Group == "Tuna/Bonito/Other Mackerel" ~ "Scombridae",
           Peskas_Group == "Goatfishes" ~ "Mullidae",
           Peskas_Group == "Sweetlips" ~ "Haemulidae",
           TRUE ~ NA_character_
         ))

# Count species per Peskas_Group
species_by_group <- species_list %>%
  count(Peskas_Group, sort = TRUE)

print(species_by_group)

# Count species per family (where family is identified)
species_by_family <- species_list %>%
  filter(!is.na(family)) %>%
  count(family, sort = TRUE)

print(species_by_family)

# Create a vector of scientific names for further analysis
scientific_names <- species_list$scientific_name

# ============================================================================
# Access FishBase data for the species
# ============================================================================

# Get basic information from FishBase
# This can take time for many species - consider doing in batches
species_info <- species_data(scientific_names, 
                             fields = c("Species", "Family", "DemersPelag", 
                                        "DepthRangeShallow", "DepthRangeDeep", 
                                        "Length", "LengthType", "Weight",
                                        "Vulnerability", "Resilience"))

# Join FishBase data with our species list
species_data_combined <- species_list %>%
  left_join(species_info, by = c("scientific_name" = "Species"))

# Show which species were matched in FishBase
matched_species <- species_data_combined %>%
  filter(!is.na(Family)) %>%
  select(scientific_name, Family, DepthRangeShallow, DepthRangeDeep, Vulnerability)

print(paste("Species matched in FishBase:", nrow(matched_species), "out of", nrow(species_list)))

# ============================================================================
# Get taxonomic verification from World Register of Marine Species (WoRMS)
# ============================================================================

# Define a function to safely match species in WoRMS
# This prevents the script from stopping if a species isn't found
safe_worrms_match <- function(species_name) {
  result <- tryCatch(
    {
      worrms::wm_records_taxamatch(species_name)
    },
    error = function(e) {
      message(paste("Error with species:", species_name))
      return(NULL)
    }
  )
  return(result)
}

# This can be slow for many species - consider running for a subset first
# Or commenting out if not immediately needed
# worms_matches <- map(scientific_names[1:10], safe_worrms_match)

# ============================================================================
# Prepare to source occurrence data from OBIS
# ============================================================================

# Define a function to safely search for occurrences in OBIS
safe_obis_search <- function(species_name) {
  result <- tryCatch(
    {
      robis::occurrence(scientificname = species_name)
    },
    error = function(e) {
      message(paste("Error with OBIS search for species:", species_name))
      return(NULL)
    }
  )
  return(result)
}

# Example of how to get occurrence data for a single species
# Again, this can be resource-intensive for many species
# timor_coords <- c(lon_min = 124.0, lon_max = 127.5, lat_min = -9.5, lat_max = -8.0)
# test_species <- scientific_names[1]
# test_occurrences <- safe_obis_search(test_species)

# ============================================================================
# Example of a function to batch process data collection
# ============================================================================

collect_species_data <- function(species_names, batch_size = 10) {
  # Initialize results list
  all_results <- list()
  
  # Process in batches
  total_species <- length(species_names)
  num_batches <- ceiling(total_species / batch_size)
  
  for (i in 1:num_batches) {
    # Calculate batch indices
    start_idx <- (i-1) * batch_size + 1
    end_idx <- min(i * batch_size, total_species)
    
    # Get current batch
    current_batch <- species_names[start_idx:end_idx]
    
    # Process batch (example with FishBase)
    batch_results <- species_data(current_batch, 
                                  fields = c("Species", "Family", "Vulnerability", "Resilience"))
    
    # Store results
    all_results[[i]] <- batch_results
    
    # Print progress
    cat(sprintf("Processed batch %d of %d (%d species)\n", 
                i, num_batches, length(current_batch)))
    
    # Be nice to the API
    Sys.sleep(2)
  }
  
  # Combine all results
  combined_results <- bind_rows(all_results)
  return(combined_results)
}

# Example usage (commented out - uncomment when ready to use)
# fishbase_data <- collect_species_data(scientific_names, batch_size = 20)

# ============================================================================
# Save processed data
# ============================================================================

# Save the enhanced species dataset
write.csv(species_data_combined, "timor_leste_species_with_data.csv", row.names = FALSE)

# ============================================================================
# Visualization examples
# ============================================================================

# Plot number of species by group
ggplot(species_by_group[1:15,], aes(x = reorder(Peskas_Group, n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Number of Species by Group (Top 15)",
       x = "Species Group",
       y = "Count") +
  theme_minimal()

# If you have vulnerability data from FishBase, visualize it
if ("Vulnerability" %in% colnames(species_data_combined)) {
  species_data_combined %>%
    filter(!is.na(Vulnerability)) %>%
    ggplot(aes(x = Vulnerability)) +
    geom_histogram(bins = 10, fill = "salmon", color = "black") +
    labs(title = "Distribution of Species Vulnerability",
         x = "Vulnerability Score",
         y = "Count") +
    theme_minimal()
}

# ============================================================================
# Example for spatial data visualization (if you have occurrence data)
# ============================================================================

# This is a template for when you have occurrence data
plot_species_occurrences <- function(occurrences, species_name) {
  # Filter valid coordinates
  valid_occurrences <- occurrences %>%
    filter(!is.na(decimalLongitude), !is.na(decimalLatitude))
  
  if(nrow(valid_occurrences) == 0) {
    return(message("No valid coordinates for ", species_name))
  }
  
  # Create a leaflet map
  map <- leaflet(valid_occurrences) %>%
    addTiles() %>%
    addCircleMarkers(
      lng = ~decimalLongitude,
      lat = ~decimalLatitude,
      radius = 5,
      color = "blue",
      stroke = FALSE,
      fillOpacity = 0.7,
      popup = ~paste("Date:", eventDate, "<br>",
                     "Location:", locality)
    ) %>%
    addLegend(
      position = "bottomright",
      colors = "blue",
      labels = species_name,
      title = "Species"
    )
  
  return(map)
}

# Example usage (commented out - uncomment when you have occurrence data)
# if (exists("test_occurrences") && !is.null(test_occurrences) && nrow(test_occurrences) > 0) {
#   plot_species_occurrences(test_occurrences, test_species)
# }

# ============================================================================
# Next steps - ideas for further analysis
# ============================================================================

# 1. Expand data collection to include:
#    - Climate vulnerability scores
#    - Fisheries importance/catch data
#    - Local ecological knowledge
#    - Conservation status (IUCN Red List)

# 2. Spatial analysis:
#    - Map species distributions along Timor-Leste coast
#    - Identify biodiversity hotspots
#    - Compare north coast vs south coast species assemblages

# 3. Ecological analysis:
#    - Group species by functional roles in reef ecosystems
#    - Assess trophic levels and food web connections
#    - Evaluate ecosystem services provided

print("Script completed successfully")