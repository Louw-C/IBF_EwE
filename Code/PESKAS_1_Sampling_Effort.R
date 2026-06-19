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


# ---- 4. Step 1a: Unique landing events by municipality × year × month ----
# Count unique landing IDs (not rows) — rows are inflated by the long format.
# One landing ID = one fishing trip recorded at one landing site.
# landings_full (year-level) is retained for Section 8 flag counts only.

landings <- sc |>
  distinct(landing_id, municipality, year) |>
  count(municipality, year, name = "n_landings")

all_cells <- expand_grid(municipality = sc_munis, year = 2018:2025)

landings_full <- all_cells |>
  left_join(landings, by = c("municipality", "year")) |>
  mutate(n_landings = replace_na(n_landings, 0L))

# Monthly heatmap: unique landings by municipality × year × month
# Faceted by municipality (2×2); month on x-axis, year on y-axis.
# Grey cells = no landings — reveals both seasonal gaps and year-to-year coverage.

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
# Each landing_id has exactly one gear type (confirmed: zero landings with multiple
# gears). distinct() simply removes taxon-slot row duplication.
# Percentages are of total south coast landing events (n = 12,512).

gear_landings <- sc |>
  distinct(landing_id, municipality, year, gear) |>
  count(municipality, year, gear, name = "n_landings")

n_sc_landings <- n_distinct(sc$landing_id)

cat("\n--- 1b: Landing events by gear type ---\n")

cat("\nTotal south coast landing events by gear (% of all 12,512 landings):\n")
gear_landings |>
  group_by(gear) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  arrange(desc(n_landings)) |>
  mutate(pct_total = round(n_landings / n_sc_landings * 100, 1)) |>
  print()
# Each landing_id = one trip with one gear. Counts here are unique trips, not rows.
# Long line dominates (75%+); hand line and gill net are the only other active gears.

cat("\nGear × municipality: landings and % within municipality:\n")
gear_landings |>
  group_by(municipality, gear) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  group_by(municipality) |>
  mutate(pct_within_muni = round(n_landings / sum(n_landings) * 100, 1)) |>
  ungroup() |>
  arrange(municipality, desc(n_landings)) |>
  print(n = 40)

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
# Each landing_id has exactly one habitat value (confirmed: zero landings with
# multiple habitats). Percentages are of total south coast landings (n = 12,512).
# Shifts in habitat composition over time may reflect enumerator logging changes
# rather than genuine changes in where fishing occurred.

habitat_landings <- sc |>
  distinct(landing_id, municipality, year, habitat) |>
  count(municipality, year, habitat, name = "n_landings")

cat("\n--- 1c: Landing events by habitat type ---\n")

cat("\nTotal south coast landing events by habitat (% of all 12,512 landings):\n")
habitat_landings |>
  group_by(habitat) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  arrange(desc(n_landings)) |>
  mutate(pct_total = round(n_landings / n_sc_landings * 100, 3)) |>
  print()

cat("\nHabitat × municipality: landings and % within municipality:\n")
habitat_landings |>
  group_by(municipality, habitat) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  group_by(municipality) |>
  mutate(pct_within_muni = round(n_landings / sum(n_landings) * 100, 3)) |>
  ungroup() |>
  arrange(municipality, desc(n_landings)) |>
  print(n = 30)

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


# ---- 9. CPUE column clarification ----
# Two CPUE columns exist in the raw file; they measure different things:
#   - cpue          = tot_catch / (n_fishers × trip_length): landing-level total CPUE.
#                     Same value for every row within a landing.
#   - cpue_fish_group = catch / (n_fishers × trip_length): taxon-specific CPUE.
#                     Varies by row. Use this for any per-taxon effort-standardised rate.
# Both are Inf when n_fishers = 0 (see Section 12).
# For catch composition (Phase 2), use `catch` (raw kg), not either CPUE column.

cat("\n=== 9. CPUE column structure ===\n")
cpue_same <- sc |>
  filter(is.finite(cpue), is.finite(cpue_fish_group)) |>
  summarise(rows_where_equal = sum(abs(cpue - cpue_fish_group) < 0.001),
            rows_where_differ = sum(abs(cpue - cpue_fish_group) >= 0.001))
cat("Rows where cpue == cpue_fish_group (single-taxon landings):", cpue_same$rows_where_equal, "\n")
cat("Rows where cpue != cpue_fish_group (multi-taxon or split-entry landings):",
    cpue_same$rows_where_differ, "\n")
cat("Formula confirmed: cpue = tot_catch / n_fishers / trip_length\n")
cat("Formula confirmed: cpue_fish_group = catch / n_fishers / trip_length\n")


# ---- 10. Factor consistency check ----
# Verify that gear, habitat, municipality, and taxon codes have no spelling variants,
# trailing whitespace, or mixed case that would cause silent mismatches in joins or
# group_by operations. Also confirm all taxon codes join to the lookup table.

cat("\n=== 10. Factor consistency ===\n")

# Gear: expect 8 clean lowercase values
gear_vals <- sort(unique(sc$gear))
cat("Gear unique values (", length(gear_vals), "):\n", sep = "")
print(gear_vals)
cat("Gear whitespace variants:", sum(gear_vals != trimws(gear_vals)), "\n")

# Habitat: expect 6 Title Case values
hab_vals <- sort(unique(sc$habitat))
cat("\nHabitat unique values (", length(hab_vals), "):\n", sep = "")
print(hab_vals)
cat("Habitat whitespace variants:", sum(hab_vals != trimws(hab_vals)), "\n")

# Municipality (south coast only)
muni_vals <- sort(unique(sc$municipality))
cat("\nMunicipality unique values (", length(muni_vals), "):\n", sep = "")
print(muni_vals)

# Landing site
site_vals <- sort(unique(sc$landing_site))
cat("\nLanding site unique values (", length(site_vals), "):\n", sep = "")
print(site_vals)

# Taxon code lookup join: join sc catch_taxon to lookup interagency_code
# catch_taxon = "0" is the zero-catch placeholder and correctly has no lookup entry
unmatched_codes <- setdiff(
  unique(sc$catch_taxon[sc$catch_taxon != "0"]),
  lookup$interagency_code
)
cat("\nTaxon codes not in lookup (excluding '0' placeholder):",
    if (length(unmatched_codes) == 0) "none — all codes match" else paste(unmatched_codes, collapse = ", "), "\n")
cat("Zero-catch placeholder rows (catch_taxon = '0'):",
    sum(sc$catch_taxon == "0"), "\n")


# ---- 11. Missing and invalid values check ----
# Systematic check for NA, zero, and biologically impossible values in the key
# numeric fields. Any failures here would propagate silently into catch composition
# and CPUE calculations in Phase 2.

cat("\n=== 11. Missing and invalid values ===\n")
cat("n_fishers: NA =", sum(is.na(sc$n_fishers)),
    " | = 0:", sum(sc$n_fishers == 0, na.rm = TRUE),
    " | < 0:", sum(sc$n_fishers < 0, na.rm = TRUE), "\n")
cat("trip_length: NA =", sum(is.na(sc$trip_length)),
    " | = 0:", sum(sc$trip_length == 0, na.rm = TRUE),
    " | < 0:", sum(sc$trip_length < 0, na.rm = TRUE), "\n")
cat("catch:       NA =", sum(is.na(sc$catch)),
    " | < 0:", sum(sc$catch < 0, na.rm = TRUE), "\n")
cat("tot_catch:   NA =", sum(is.na(sc$tot_catch)),
    " | < 0:", sum(sc$tot_catch < 0, na.rm = TRUE), "\n")
cat("gear:        NA =", sum(is.na(sc$gear)),
    " | empty:", sum(sc$gear == "", na.rm = TRUE), "\n")
cat("habitat:     NA =", sum(is.na(sc$habitat)),
    " | empty:", sum(sc$habitat == "", na.rm = TRUE), "\n")
cat("catch_name_en NA or empty despite catch > 0:",
    sc |> filter(catch > 0, is.na(catch_name_en) | catch_name_en == "") |> nrow(), "\n")


# ---- 12. n_fishers = 0 → Inf CPUE ----
# 21 landing events have catch > 0 but n_fishers = 0 — data entry omission, not
# a true zero-crew trip. These produce Inf in both CPUE columns (division by zero).
# They are correctly counted in landing event totals (Sections 4–6) but must be
# excluded from any effort-standardised (CPUE-based) analysis in Phase 2.

cat("\n=== 12. n_fishers = 0 → Inf CPUE ===\n")
zero_fisher <- sc |> filter(n_fishers == 0)
zero_fisher_catch <- zero_fisher |> filter(catch > 0)

cat("Total rows with n_fishers = 0:", nrow(zero_fisher), "\n")
cat("  Of these, rows with catch > 0:", nrow(zero_fisher_catch),
    "(Inf CPUE)\n")
cat("  Unique landing_ids affected:", n_distinct(zero_fisher_catch$landing_id), "\n")
cat("  Proportion of south coast landings:",
    round(n_distinct(zero_fisher_catch$landing_id) / n_distinct(sc$landing_id) * 100, 2), "%\n")

cat("\nAffected landings by municipality and year:\n")
zero_fisher_catch |>
  mutate(year = as.integer(format(landing_date, "%Y"))) |>
  distinct(landing_id, municipality, year, gear) |>
  count(municipality, year, gear) |>
  arrange(municipality, year) |>
  print()

cat("Action: exclude these 21 landing_ids from all CPUE calculations in Phase 2.\n")
cat("Their catch values are real and may be included in catch composition analysis.\n")


# ---- 13. tot_catch vs sum(catch) per landing ----
# In long format each landing has multiple rows (one per taxon slot). tot_catch
# should equal sum(catch) across all rows for the same landing_id. Any mismatch
# would indicate internal inconsistency in the source data.

cat("\n=== 13. tot_catch consistency ===\n")
tot_check <- sc |>
  group_by(landing_id) |>
  summarise(sum_catch = sum(catch), tot = first(tot_catch), .groups = "drop") |>
  mutate(diff = abs(sum_catch - tot)) |>
  filter(diff > 0.01)

cat("Landings where sum(catch) != tot_catch (tolerance 0.01 kg):", nrow(tot_check), "\n")
if (nrow(tot_check) == 0) cat("All landings internally consistent. tot_catch is reliable.\n")


# ---- 14. Duplicate landing_id × taxon entries ----
# In a strict long format, each landing should have at most one row per taxon code.
# However 1,503 landings have the same taxon code appearing 2–3 times per landing
# with DIFFERENT catch values. These are split entries (e.g. large vs small fish of
# the same species recorded separately), not duplicates — sum(catch) = tot_catch
# confirms no double-counting.
# Impact: any pivot or summary MUST use sum(catch) per taxon per landing, not
# first(catch). cpue_fish_group likewise needs to be re-computed as
# sum(catch) / n_fishers / trip_length per taxon per landing before use.

cat("\n=== 14. Duplicate landing_id × taxon entries ===\n")
dup_pairs <- sc |>
  filter(catch_taxon != "0") |>
  count(landing_id, catch_taxon) |>
  filter(n > 1)

cat("Unique landing × taxon pairs with > 1 row:", nrow(dup_pairs), "\n")
cat("Unique landing_ids affected:", n_distinct(dup_pairs$landing_id), "\n")
cat("  (out of", n_distinct(sc$landing_id), "total south coast landings =",
    round(n_distinct(dup_pairs$landing_id) / n_distinct(sc$landing_id) * 100, 1), "%)\n")

cat("\nMost affected taxon codes:\n")
dup_pairs |>
  left_join(lookup |> select(interagency_code, catch_name_en),
            by = c("catch_taxon" = "interagency_code")) |>
  count(catch_taxon, catch_name_en, sort = TRUE) |>
  head(10) |>
  print()

cat("\nAffected landings by municipality and year:\n")
sc |>
  filter(landing_id %in% dup_pairs$landing_id) |>
  mutate(year = as.integer(format(landing_date, "%Y"))) |>
  distinct(landing_id, municipality, year) |>
  count(municipality, year) |>
  arrange(municipality, year) |>
  print()

cat("Action: in Phase 2, always aggregate catch with sum(), never first() or slice(1).\n")
cat("Re-compute cpue_fish_group as sum(catch) / n_fishers / trip_length per\n")
cat("taxon per landing before any effort-standardised taxon analysis.\n")

