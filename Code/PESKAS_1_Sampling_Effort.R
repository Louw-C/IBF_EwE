# PESKAS_1_Sampling_Effort.R
# Phase 1 — Sampling effort investigation, south coast Timor-Leste
#
# Assesses data coverage before any catch or composition analysis:
#   1a. Unique landing events by municipality × year
#   1b. Gear coverage by municipality × year
#   1c. Rows-per-landing distribution — flags protocol changes
#
# Input:  Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv  (READ ONLY)
#         Data/raw/Fisheries/Peskas groups_From Lore.csv          (READ ONLY)
# Output: Figures/PESKAS_1a_landing_events_heatmap.png
#         Figures/PESKAS_1b_gear_coverage.png
#         Figures/PESKAS_1c_rows_per_landing.png
# -----------------------------------------------------------------------


# ---- 1. Packages ----
# tidyverse covers readr, dplyr, tidyr, ggplot2, stringr
# RColorBrewer provides colour palettes for figures

library(tidyverse)
library(RColorBrewer)


# ---- 2. Load raw data ----
# - cpue: landing-level CPUE file; one row per taxon slot per landing (incl. zeros)
# - lookup: maps interagency codes to full English names, Tetum names, family
# Raw files are never modified; all outputs go to Figures/ or Data/processed/

cpue <- read_csv(
  "Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv",
  show_col_types = FALSE
)

lookup <- read_csv(
  "Data/raw/Fisheries/Peskas groups_From Lore.csv",
  show_col_types = FALSE
)

# Sanity checks
cat("CPUE rows:", nrow(cpue), "\n")                    # Expected: 221,258
cat("Lookup groups:", nrow(lookup), "\n")              # Expected: 59
cat("CPUE columns:", paste(names(cpue), collapse = ", "), "\n")


# ---- 3. Filter to south coast ----
# IBF focus municipalities: Covalima, Ainaro, Manufahi, Viqueque
# Extract year from landing_date for temporal grouping

sc_munis <- c("Covalima", "Ainaro", "Manufahi", "Viqueque")

sc <- cpue |>
  filter(municipality %in% sc_munis) |>
  mutate(year = as.integer(format(as.Date(landing_date), "%Y")))

cat("\nSouth coast rows:", nrow(sc), "\n")             # Expected: ~58,127
cat("South coast unique landings:", n_distinct(sc$landing_id), "\n")  # Expected: 12,512
cat("Year range:", min(sc$year), "–", max(sc$year), "\n")


# ---- 4. Step 1a: Unique landing events by municipality × year ----
# Count unique landing IDs (not rows) — rows are inflated by the long format.
# One landing ID = one fishing trip recorded at one landing site.
# Flag: < 20 landings in a cell = low confidence for catch composition analysis.

landings <- sc |>
  distinct(landing_id, municipality, year) |>
  count(municipality, year, name = "n_landings")

# Complete grid: fill year–municipality combinations with zero if absent
all_cells <- expand_grid(municipality = sc_munis, year = 2018:2025)

landings_full <- all_cells |>
  left_join(landings, by = c("municipality", "year")) |>
  mutate(n_landings = replace_na(n_landings, 0L))

# Print wide summary table
cat("\n--- 1a: Unique landing events by municipality × year ---\n")
landings_full |>
  pivot_wider(names_from = municipality, values_from = n_landings) |>
  arrange(year) |>
  print()

cat("\nTotal landings per municipality:\n")
landings_full |>
  group_by(municipality) |>
  summarise(total = sum(n_landings), .groups = "drop") |>
  arrange(desc(total)) |>
  print()
# Viqueque and Covalima should dominate; Ainaro smallest

cat("\nLow-confidence cells (< 20 landings):\n")
landings_full |>
  filter(n_landings < 20) |>
  arrange(municipality, year) |>
  print()

# Monthly heatmap: unique landings by municipality × year × month
# Shows both seasonal coverage patterns and year-to-year gaps in one view.
# Faceted by municipality (2×2); month on x-axis, year on y-axis.

month_labels <- c("Jan","Feb","Mar","Apr","May","Jun",
                  "Jul","Aug","Sep","Oct","Nov","Dec")

landings_month <- sc |>
  mutate(month = as.integer(format(as.Date(landing_date), "%m"))) |>
  distinct(landing_id, municipality, year, month) |>
  count(municipality, year, month, name = "n_landings")

# Complete grid: all municipality × year × month combinations
all_month_cells <- expand_grid(
  municipality = sc_munis,
  year         = 2018:2025,
  month        = 1:12
)

landings_month_full <- all_month_cells |>
  left_join(landings_month, by = c("municipality", "year", "month")) |>
  mutate(
    n_landings  = replace_na(n_landings, 0L),
    # NA used for fill so zero cells render as grey (na.value); keep n_landings for labels
    fill_value  = ifelse(n_landings == 0, NA_integer_, n_landings),
    label       = as.character(n_landings),
    # White text on dark cells; dark text on light or grey cells
    text_colour = ifelse(n_landings > 100, "white", "grey20")
  )

p1a_month <- ggplot(landings_month_full,
                    aes(x = factor(month, labels = month_labels),
                        y = factor(year, levels = rev(2018:2025)),
                        fill = fill_value)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_colour),
            size = 2.4, fontface = "bold") +
  facet_wrap(~municipality, ncol = 2) +
  scale_fill_gradient(low = "#e8f5e9", high = "#1b5e20",
                      na.value = "grey85",
                      name = "Unique\nlandings") +
  scale_colour_identity() +
  labs(
    title    = "Step 1a: Unique landing events by municipality, year, and month",
    subtitle = "Grey cells = no landings recorded. Reveals seasonal monitoring gaps alongside year-to-year coverage.",
    x        = NULL, y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid    = element_blank(),
        axis.text.x   = element_text(size = 7),
        strip.text    = element_text(face = "bold"),
        plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(size = 9, colour = "grey40"))

ggsave("Figures/PESKAS_1a_landing_events_monthly_heatmap.png",
       p1a_month, width = 10, height = 7, dpi = 300)
cat("Saved: Figures/PESKAS_1a_landing_events_monthly_heatmap.png\n")


# ---- 5. Step 1b: Gear coverage by municipality × year ----
# Count unique landing events per gear type within each municipality × year.
# Each landing_id has one gear type; distinct() removes the taxon-slot duplication.
# Goal: check whether gear composition is stable over time or shifts (possible
# sampling frame change) and identify gear types with very few landings.

gear_landings <- sc |>
  distinct(landing_id, municipality, year, gear) |>
  count(municipality, year, gear, name = "n_landings")

cat("\n--- 1b: Landing events by gear type ---\n")

cat("\nTotal south coast landing events by gear:\n")
gear_landings |>
  group_by(gear) |>
  summarise(total = sum(n_landings), .groups = "drop") |>
  arrange(desc(total)) |>
  print()
# Long line expected to dominate; beach seine and manual collection very minor

cat("\nGear × municipality totals:\n")
gear_landings |>
  group_by(municipality, gear) |>
  summarise(total = sum(n_landings), .groups = "drop") |>
  pivot_wider(names_from = gear, values_from = total, values_fill = 0L) |>
  print()

# Stacked bar: gear composition per municipality over time
# Free y-scale per facet because Covalima/Viqueque dwarf Ainaro
gear_cols <- brewer.pal(8, "Set2")[seq_len(n_distinct(gear_landings$gear))]

p1b <- ggplot(gear_landings,
              aes(x = factor(year), y = n_landings, fill = gear)) +
  geom_col(colour = "white", linewidth = 0.3) +
  facet_wrap(~municipality, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = gear_cols, name = "Gear type") +
  labs(
    title    = "Step 1b: Landing events by gear type, municipality, and year",
    subtitle = "Unique landing events (not rows). Y-axes free — municipalities differ greatly in effort.",
    x        = "Year", y = "Unique landing events"
  ) +
  theme_minimal(base_size = 10) +
  theme(axis.text.x    = element_text(angle = 45, hjust = 1),
        strip.text     = element_text(face = "bold"),
        plot.title     = element_text(face = "bold"),
        plot.subtitle  = element_text(size = 9, colour = "grey40"),
        legend.position = "bottom")

ggsave("Figures/PESKAS_1b_gear_coverage.png",
       p1b, width = 9, height = 6, dpi = 300)
cat("Saved: Figures/PESKAS_1b_gear_coverage.png\n")


# ---- 6. Step 1c: Habitat coverage by municipality × year ----
# Count unique landing events per habitat type within each municipality × year.
# Shifts in habitat composition over time can indicate changes in how enumerators
# logged habitats (protocol change) rather than genuine changes in where fishing occurred.

habitat_landings <- sc |>
  distinct(landing_id, municipality, year, habitat) |>
  count(municipality, year, habitat, name = "n_landings")

cat("\n--- 1c: Landing events by habitat type ---\n")

cat("\nTotal south coast landing events by habitat:\n")
habitat_landings |>
  group_by(habitat) |>
  summarise(total = sum(n_landings), .groups = "drop") |>
  arrange(desc(total)) |>
  print()

cat("\nHabitat × municipality totals:\n")
habitat_landings |>
  group_by(municipality, habitat) |>
  summarise(total = sum(n_landings), .groups = "drop") |>
  pivot_wider(names_from = habitat, values_from = total, values_fill = 0L) |>
  print()

# Stacked bar: habitat composition per municipality over time
hab_cols <- brewer.pal(max(3, n_distinct(habitat_landings$habitat)), "Set1")[
  seq_len(n_distinct(habitat_landings$habitat))]

p1c_hab <- ggplot(habitat_landings,
                  aes(x = factor(year), y = n_landings, fill = habitat)) +
  geom_col(colour = "white", linewidth = 0.3) +
  facet_wrap(~municipality, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = hab_cols, name = "Habitat") +
  labs(
    title    = "Step 1c: Landing events by habitat type, municipality, and year",
    subtitle = "Unique landing events (not rows). Shifts in habitat mix may reflect enumerator logging changes.",
    x        = "Year", y = "Unique landing events"
  ) +
  theme_minimal(base_size = 10) +
  theme(axis.text.x     = element_text(angle = 45, hjust = 1),
        strip.text      = element_text(face = "bold"),
        plot.title      = element_text(face = "bold"),
        plot.subtitle   = element_text(size = 9, colour = "grey40"),
        legend.position = "bottom")

ggsave("Figures/PESKAS_1c_habitat_coverage.png",
       p1c_hab, width = 9, height = 6, dpi = 300)
cat("Saved: Figures/PESKAS_1c_habitat_coverage.png\n")


# ---- 7. Step 1d: Rows-per-landing distribution ----
# The CPUE file is long format: each landing generates multiple rows (one per
# taxon slot offered to the enumerator, including zeros). Typical range is ~10–35.
# A spike in rows-per-landing signals that the taxon slot set was expanded —
# a protocol change that inflates row counts without adding new landing events.
# Flag: landings with > 50 rows; summarise by municipality × year.

rows_per_landing <- sc |>
  count(landing_id, municipality, year, name = "n_rows")

cat("\n--- 1d: Rows per landing ---\n")
cat("Min:", min(rows_per_landing$n_rows), "\n")
cat("Median:", median(rows_per_landing$n_rows), "\n")
cat("Mean:", round(mean(rows_per_landing$n_rows), 1), "\n")
cat("Max:", max(rows_per_landing$n_rows), "\n")
cat("Landings > 50 rows:", sum(rows_per_landing$n_rows > 50), "\n")
cat("% landings > 50 rows:",
    round(mean(rows_per_landing$n_rows > 50) * 100, 1), "%\n")

cat("\nFlagged landings (> 50 rows) by municipality × year:\n")
rows_per_landing |>
  filter(n_rows > 50) |>
  count(municipality, year, name = "n_flagged") |>
  arrange(municipality, year) |>
  print()
# If Covalima 2024 has most flags, this confirms the row-count anomaly
# (646 unique landings → 21,759 rows ≈ 34 rows/landing vs typical ~10)

# Heatmap: mean rows per landing by municipality × year
# A jump in mean rows signals taxon slot expansion (protocol change), not more fishing.
# More direct than a histogram for detecting when and where the change occurred.

mean_rows <- rows_per_landing |>
  group_by(municipality, year) |>
  summarise(mean_rows = round(mean(n_rows), 1), .groups = "drop")

all_cells <- expand_grid(municipality = sc_munis, year = 2018:2025)

mean_rows_full <- all_cells |>
  left_join(mean_rows, by = c("municipality", "year")) |>
  mutate(
    fill_value  = ifelse(is.na(mean_rows), NA_real_, mean_rows),
    label       = ifelse(is.na(mean_rows), "0", as.character(mean_rows)),
    text_colour = ifelse(!is.na(mean_rows) & mean_rows > 20, "white", "grey20")
  )

p1d <- ggplot(mean_rows_full,
              aes(x = factor(year), y = municipality, fill = fill_value)) +
  geom_tile(colour = "white", linewidth = 0.7) +
  geom_text(aes(label = label, colour = text_colour),
            size = 3.3, fontface = "bold") +
  scale_fill_gradient(low = "#e8f5e9", high = "#1b5e20",
                      na.value = "grey85",
                      name = "Mean rows\nper landing") +
  scale_colour_identity() +
  labs(
    title    = "Step 1d: Mean rows per landing by municipality and year",
    subtitle = "A sudden increase indicates taxon slot expansion in the recording system, not more fishing effort.",
    x        = "Year", y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid    = element_blank(),
        axis.text.y   = element_text(face = "bold"),
        plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(size = 9, colour = "grey40"))

ggsave("Figures/PESKAS_1d_rows_per_landing.png",
       p1d, width = 8, height = 3.8, dpi = 300)
cat("Saved: Figures/PESKAS_1d_rows_per_landing.png\n")


# ---- 8. Phase 1 data quality flags — printed summary ----
# Known gaps and anomalies confirmed from data structure.
# These are facts, not inferences; each needs a targeted question for the PESKAS team.

cov21 <- landings_full |> filter(municipality == "Covalima", year == 2021) |> pull(n_landings)
cov23 <- landings_full |> filter(municipality == "Covalima", year == 2023) |> pull(n_landings)
cov24 <- landings_full |> filter(municipality == "Covalima", year == 2024) |> pull(n_landings)
viq18 <- landings_full |> filter(municipality == "Viqueque",  year == 2018) |> pull(n_landings)

cat("\n========== PHASE 1 DATA QUALITY FLAGS ==========\n")
cat("1. Manufahi 2022: 0 unique landings — complete monitoring gap.\n",
    "   Question: staff change, funding gap, or data loss?\n\n")
cat("2. Ainaro: absent from 2024 onward; declining from 2021 (93 landings) to 2023 (23).\n",
    "   Question: were landing sites dropped from the monitoring frame?\n\n")
cat("3. Viqueque 2018:", viq18, "landings — early ramp-up; treat as low confidence.\n\n")
cat("4. Covalima anomaly: 2021 =", cov21, "→ 2023 =", cov23, "→ 2024 =", cov24, "landings.\n",
    "   Question: did monitored landing sites change between these years?\n\n")
cat("5. Covalima 2024 row inflation: 646 unique landings → 21,759 rows (~34 rows/landing).\n",
    "   Typical for other years: ~10–15 rows/landing.\n",
    "   Question: was the taxon slot list expanded in the 2024 data entry system?\n\n")
cat("6. Viqueque 2018 gear flag: hand line count in 2018 may include trips that should\n",
    "   be long line — first-year recording inconsistency.\n\n")
cat("7. Manufahi hand line vs long line: no long line recorded across any year despite\n",
    "   the gear being common elsewhere on the south coast. Manufahi enumerators may\n",
    "   record attended multi-hook bottom lines as hand line. Field verification needed.\n\n")
cat("8. Viqueque beach seine: small number of beach seine landings — confirm with\n",
    "   enumerators whether these are beach seines or gill nets set near the shoreline.\n\n")
cat("9. Viqueque FAD 2018: check whether a FAD was actually deployed in Viqueque in 2018.\n",
    "   If not, FAD landings that year are misclassified habitat records.\n\n")
cat("10. Manufahi Reef: field knowledge suggests fishing does not always occur on reef.\n",
    "    Reef may be used as a default habitat label rather than the actual fishing ground.\n\n")
cat("11. Ainaro Reef vs Deep: suspected reclassification between these two categories\n",
    "    across years. Boundary between reef and deep is undefined in the PESKAS protocol.\n")
cat("=================================================\n")
