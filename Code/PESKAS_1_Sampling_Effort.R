# PESKAS_1_Sampling_Effort.R
# Phase 1 — Sampling effort investigation, south coast Timor-Leste
#
# Assesses data coverage before any catch or composition analysis:
#   1a. Unique landing events by municipality × year × month
#   1b. Gear coverage by municipality × year
#   1c. Habitat coverage by municipality × year
#   1d–1f. Zero-catch rate by municipality/gear/habitat
#
# Input:  Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv  (READ ONLY)
#         Data/raw/Fisheries/Peskas groups_From Lore.csv          (READ ONLY)
# Output: Figures/PESKAS_1a_landing_events_monthly_heatmap.png
#         Figures/PESKAS_1b_gear_coverage.png
#         Figures/PESKAS_1c_habitat_coverage.png
#         Figures/PESKAS_1e_zero_catch_year.png
#         Figures/PESKAS_1f_zero_catch_gear.png
#         Figures/PESKAS_1g_zero_catch_habitat.png
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

# Remove gears and habitats with fewer than 20 landing events (all landings
# included, catch = 0 and catch > 0) — consistent with Scripts 2 and 3.
# This filter is applied to ALL analyses in this script, including the zero-catch
# exploration (Sections 15–18). Figures show only the retained dataset.
gear_counts_all <- sc |> distinct(landing_id, gear)    |> count(gear,    name = "n_landings")
hab_counts_all  <- sc |> distinct(landing_id, habitat) |> count(habitat, name = "n_landings")
rare_gears <- gear_counts_all |> filter(n_landings < 20) |> pull(gear)
rare_habs  <- hab_counts_all  |> filter(n_landings < 20) |> pull(habitat)

if (length(rare_gears) > 0 || length(rare_habs) > 0) {
  n_total     <- n_distinct(sc$landing_id)
  muni_totals <- sc |> distinct(landing_id, municipality) |> count(municipality, name = "n_muni_total")
  removed     <- sc |>
    filter(gear %in% rare_gears | habitat %in% rare_habs) |>
    distinct(landing_id, municipality)
  n_removed   <- n_distinct(removed$landing_id)

  cat("\nGears removed (< 20 landing events):\n")
  gear_counts_all |>
    filter(n_landings < 20) |>
    mutate(pct_of_total = round(n_landings / n_total * 100, 2)) |>
    print()

  cat("\nHabitats removed (< 20 landing events):\n")
  hab_counts_all |>
    filter(n_landings < 20) |>
    mutate(pct_of_total = round(n_landings / n_total * 100, 2)) |>
    print()

  cat(sprintf("\nTotal removed: %d landings (%.2f%% of %d south coast landings)\n",
              n_removed, n_removed / n_total * 100, n_total))

  cat("\nRemoved landings by municipality:\n")
  removed |>
    count(municipality, name = "n_removed") |>
    left_join(muni_totals, by = "municipality") |>
    mutate(pct_of_muni = round(n_removed / n_muni_total * 100, 2)) |>
    print()

  sc <- sc |> filter(!gear %in% rare_gears, !habitat %in% rare_habs)
  cat("South coast landings retained:", n_distinct(sc$landing_id), "\n\n")
}


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

p1a_month

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

p1b

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

p1c_hab 

ggsave("Figures/PESKAS_1c_habitat_coverage.png",
       p1c_hab, width = 9, height = 6, dpi = 300)
cat("Saved: Figures/PESKAS_1c_habitat_coverage.png\n")



# ---- 8. Phase 1 data quality flags — printed summary ----
# Known gaps and anomalies confirmed from data structure.
# These are facts, not inferences; each needs a targeted question for the PESKAS team.

cov21 <- landings_full |> filter(municipality == "Covalima", year == 2021) |> pull(n_landings)
cov23 <- landings_full |> filter(municipality == "Covalima", year == 2023) |> pull(n_landings)
cov24 <- landings_full |> filter(municipality == "Covalima", year == 2024) |> pull(n_landings)
viq18 <- landings_full |> filter(municipality == "Viqueque",  year == 2018) |> pull(n_landings)

cat("\n========== PHASE 1 DATA QUALITY FLAGS ==========\n")
cat("1. Manufahi 2022: 0 unique landings — complete monitoring gap across all 12 months.\n\n")
cat("2. Ainaro: absent from 2024 onward; declining from 2021 (93 landings) to 2023 (23).\n\n")
cat("3. Viqueque 2018:", viq18, "landings — early ramp-up; treat as low confidence.\n\n")
cat("4. Covalima: 2021 =", cov21, "→ 2023 =", cov23, "→ 2024 =", cov24,
    "landings — unexplained swings.\n\n")
cat("5. Viqueque 2018 gear: 248 hand line landings, 0 long line. From 2019 onward,\n",
    "   near-zero hand line and long line dominant — probable first-year recording\n",
    "   inconsistency.\n\n")
cat("6. Manufahi gear: no long line recorded across any year despite it being common\n",
    "   elsewhere on the south coast. Enumerators may record multi-hook set lines\n",
    "   as hand line.\n\n")
cat("7. Viqueque beach seine: small number of landings — may be gill nets set near\n",
    "   the shoreline.\n\n")
cat("8. Viqueque FAD 2018: FAD habitat accounts for 62.5%% of Viqueque 2018 landings,\n",
    "   then near-zero from 2019 onward.\n\n")
cat("9. Manufahi Reef: field knowledge suggests reef is overused as a default\n",
    "   habitat label.\n\n")
cat("10. Ainaro: ~99%% Reef (2019) → 100%% Deep (2021 onward) — abrupt switch with\n",
    "    no intermediate transition.\n")
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
# Some landing events have n_fishers = 0 — data entry omission, not a true zero-crew
# trip. These produce Inf in both CPUE columns (division by zero).
# Note: metier identification (Phases 2–3) uses raw catch weight and catch frequencies,
# not CPUE. All affected landings are retained for catch-based analyses. Exclude only
# if CPUE-based effort standardisation is needed in future.

cat("\n=== 12. n_fishers = 0 → Inf CPUE ===\n")
zero_fisher <- sc |> filter(n_fishers == 0)
zero_fisher_catch <- zero_fisher |> filter(catch > 0)

cat("Unique landing_ids with n_fishers = 0 (all):", n_distinct(zero_fisher$landing_id), "\n")
cat("  Of these, with real catch > 0 (produce Inf CPUE):",
    n_distinct(zero_fisher_catch$landing_id), "\n")
cat("  Proportion of south coast landings:",
    round(n_distinct(zero_fisher_catch$landing_id) / n_distinct(sc$landing_id) * 100, 2), "%\n")

cat("\nAffected landings (catch > 0) by municipality and year:\n")
zero_fisher_catch |>
  mutate(year = as.integer(format(landing_date, "%Y"))) |>
  distinct(landing_id, municipality, year, gear) |>
  count(municipality, year, gear) |>
  arrange(municipality, year) |>
  print()

cat("Note: metier identification uses raw catch weight and catch frequencies, not CPUE.\n")
cat("All", n_distinct(zero_fisher$landing_id), "landing events are retained for catch-based\n")
cat("analyses in Phases 2–3. Exclude from CPUE-based analyses only.\n")


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


# ---- 15. Steps 1e–1g: Zero-catch rate analysis ----
# A zero-catch landing is any landing_id where tot_catch = 0.
# tot_catch is landing-level and confirmed consistent in Section 13.
# Zero-catch landings are real recorded events — a fishing trip occurred but
# returned nothing. All landing events (catch = 0 and catch > 0) are counted,
# consistent with the < 20 threshold filter in Section 3b.

landings_flag <- sc |>
  distinct(landing_id, municipality, year, gear, habitat, tot_catch) |>
  mutate(zero_catch = tot_catch == 0)

cat("\n=== 15. Zero-catch rate summary ===\n")
cat("Total retained landing events:", nrow(landings_flag), "\n")
cat("Zero-catch landings:", sum(landings_flag$zero_catch), "\n")
cat("Overall zero-catch rate:", round(mean(landings_flag$zero_catch) * 100, 1), "%\n\n")

cat("Zero-catch rate by municipality:\n")
landings_flag |>
  group_by(municipality) |>
  summarise(n_total = n(), n_zero = sum(zero_catch),
            pct_zero = round(n_zero / n_total * 100, 1), .groups = "drop") |>
  print()

cat("\nZero-catch rate by gear:\n")
landings_flag |>
  group_by(gear) |>
  summarise(n_total = n(), n_zero = sum(zero_catch),
            pct_zero = round(n_zero / n_total * 100, 1), .groups = "drop") |>
  arrange(desc(n_total)) |>
  print()

cat("\nZero-catch rate by habitat:\n")
landings_flag |>
  group_by(habitat) |>
  summarise(n_total = n(), n_zero = sum(zero_catch),
            pct_zero = round(n_zero / n_total * 100, 1), .groups = "drop") |>
  arrange(desc(n_total)) |>
  print()


# ---- 16. Step 1e figure: Zero-catch rate by municipality, year, and month ----
# Layout mirrors Fig 1a: faceted by municipality (2×2), month on x, year on y.
# Orange-red gradient: higher % = more zero-catch events; grey = no landings.
# Uses month_labels defined in Section 4.

zero_month <- sc |>
  mutate(month = as.integer(format(as.Date(landing_date), "%m"))) |>
  distinct(landing_id, municipality, year, month, tot_catch) |>
  mutate(zero_catch = tot_catch == 0) |>
  group_by(municipality, year, month) |>
  summarise(n_total = n(), n_zero = sum(zero_catch),
            pct = round(n_zero / n_total * 100, 1), .groups = "drop")

all_month_cells_zc <- expand_grid(
  municipality = sc_munis,
  year         = 2018:2025,
  month        = 1:12
)

zero_month_full <- all_month_cells_zc |>
  left_join(zero_month, by = c("municipality", "year", "month")) |>
  mutate(
    fill_val = ifelse(is.na(n_total), NA_real_, pct),
    label    = case_when(is.na(n_total) ~ "", TRUE ~ paste0(n_zero, "/", pct, "%")),
    text_col = ifelse(!is.na(pct) & pct > 50, "white", "grey20")
  )

p1e <- ggplot(zero_month_full,
              aes(x = factor(month, labels = month_labels),
                  y = factor(year, levels = rev(2018:2025)),
                  fill = fill_val)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_col), size = 2.0, fontface = "bold") +
  facet_wrap(~municipality, ncol = 2) +
  scale_fill_gradient(low = "#fff3e0", high = "#e65100",
                      na.value = "grey85", limits = c(0, 100),
                      name = "% zero\ncatch") +
  scale_colour_identity() +
  labs(
    title    = "Step 1e: Zero-catch rate by municipality, year, and month",
    subtitle = "Numbers = n_zero / %. Grey = no landings recorded.",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid    = element_blank(),
    axis.text.x   = element_text(size = 7),
    strip.text    = element_text(face = "bold"),
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(size = 9, colour = "grey40")
  )

p1e

ggsave("Figures/PESKAS_1e_zero_catch_year.png",
       p1e, width = 10, height = 7, dpi = 300)
cat("Saved: Figures/PESKAS_1e_zero_catch_year.png\n")


# ---- 17. Step 1f figure: Zero-catch rate by gear × year, faceted by municipality ----
# Faceted by municipality (2×2); x = year, y = gear (most frequent first).
# Shows whether gear-specific zero-catch rates change over time.
# Grey = gear not used in that municipality × year.

gear_order_zc <- landings_flag |>
  count(gear, sort = TRUE) |>
  pull(gear)

zero_gear_year <- sc |>
  distinct(landing_id, municipality, year, gear, tot_catch) |>
  mutate(zero_catch = tot_catch == 0) |>
  group_by(gear, municipality, year) |>
  summarise(n_total = n(), n_zero = sum(zero_catch),
            pct = round(n_zero / n_total * 100, 1), .groups = "drop")

gear_year_grid <- expand_grid(
  gear = gear_order_zc, municipality = sc_munis, year = sort(unique(sc$year))
) |>
  left_join(zero_gear_year, by = c("gear", "municipality", "year")) |>
  mutate(
    fill_val = ifelse(is.na(n_total), NA_real_, pct),
    label    = case_when(
      is.na(n_total) ~ "",
      TRUE           ~ paste0(n_zero, "/", pct, "%")
    ),
    text_col = ifelse(!is.na(pct) & pct > 50, "white", "grey20")
  )

p1f <- ggplot(gear_year_grid,
              aes(x = factor(year),
                  y = factor(gear, levels = rev(gear_order_zc)),
                  fill = fill_val)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_col), size = 2.0, fontface = "bold") +
  facet_wrap(~municipality, ncol = 2) +
  scale_fill_gradient(low = "#fff3e0", high = "#e65100",
                      na.value = "grey85", limits = c(0, 100),
                      name = "% zero\ncatch") +
  scale_colour_identity() +
  scale_y_discrete(labels = str_to_title) +
  labs(
    title    = "Step 1f: Zero-catch rate by gear type, year, and municipality",
    subtitle = "Numbers = n_zero / %. Grey = gear not recorded in that municipality × year.",
    x = "Year", y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid    = element_blank(),
    axis.text.x   = element_text(angle = 45, hjust = 1, size = 7),
    axis.text.y   = element_text(size = 8),
    strip.text    = element_text(face = "bold"),
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(size = 9, colour = "grey40"),
    legend.position = "right"
  )

p1f

ggsave("Figures/PESKAS_1f_zero_catch_gear.png",
       p1f, width = 10, height = 6, dpi = 300)
cat("Saved: Figures/PESKAS_1f_zero_catch_gear.png\n")


# ---- 18. Step 1g figure: Zero-catch rate by habitat × year, faceted by municipality ----
# Faceted by municipality (2×2); x = year, y = habitat (most frequent first).
# Grey = habitat not recorded in that municipality × year.

hab_order_zc <- landings_flag |>
  count(habitat, sort = TRUE) |>
  pull(habitat)

zero_hab_year <- sc |>
  distinct(landing_id, municipality, year, habitat, tot_catch) |>
  mutate(zero_catch = tot_catch == 0) |>
  group_by(habitat, municipality, year) |>
  summarise(n_total = n(), n_zero = sum(zero_catch),
            pct = round(n_zero / n_total * 100, 1), .groups = "drop")

hab_year_grid <- expand_grid(
  habitat = hab_order_zc, municipality = sc_munis, year = sort(unique(sc$year))
) |>
  left_join(zero_hab_year, by = c("habitat", "municipality", "year")) |>
  mutate(
    fill_val = ifelse(is.na(n_total), NA_real_, pct),
    label    = case_when(
      is.na(n_total) ~ "",
      TRUE           ~ paste0(n_zero, "/", pct, "%")
    ),
    text_col = ifelse(!is.na(pct) & pct > 50, "white", "grey20")
  )

p1g <- ggplot(hab_year_grid,
              aes(x = factor(year),
                  y = factor(habitat, levels = rev(hab_order_zc)),
                  fill = fill_val)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_col), size = 2.0, fontface = "bold") +
  facet_wrap(~municipality, ncol = 2) +
  scale_fill_gradient(low = "#fff3e0", high = "#e65100",
                      na.value = "grey85", limits = c(0, 100),
                      name = "% zero\ncatch") +
  scale_colour_identity() +
  labs(
    title    = "Step 1g: Zero-catch rate by habitat type, year, and municipality",
    subtitle = "Numbers = n_zero / %. Grey = habitat not recorded in that municipality × year.",
    x = "Year", y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid    = element_blank(),
    axis.text.x   = element_text(angle = 45, hjust = 1, size = 7),
    axis.text.y   = element_text(size = 8),
    strip.text    = element_text(face = "bold"),
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(size = 9, colour = "grey40"),
    legend.position = "right"
  )

p1g

ggsave("Figures/PESKAS_1g_zero_catch_habitat.png",
       p1g, width = 10, height = 6, dpi = 300)
cat("Saved: Figures/PESKAS_1g_zero_catch_habitat.png\n")


# ---- 19. Questions for the PESKAS team (Phase 1) ----
# Based on monitoring coverage (Sections 4–6) and gear flags (Section 8).
# Additional gear questions (sabiki rigs, gear definitions) are in Script 2.
# Habitat questions are in Script 3.

cat("\n========== QUESTIONS FOR THE PESKAS TEAM — PHASE 1 ==========\n\n")

cat("--- A. Monitoring coverage ---\n\n")
cat("Q1. Manufahi 2022 has zero recorded landings across all months. Was this a\n",
    "    monitoring gap (staff change, funding interruption) or data loss?\n\n")
cat("Q2. Ainaro is absent from 2024 and has been declining since 2021\n",
    "    (136 → 93 → 23 landings). Were landing sites dropped from the monitoring\n",
    "    frame, or did monitoring stop altogether?\n\n")
cat("Q3. Covalima shows unexplained swings in landing counts: 2,024 (2021) → 272 (2023)\n",
    "    → 646 (2024). Did the set of monitored landing sites change between these years,\n",
    "    or is this an actual change in the number of landings?\n\n")

cat("--- B. Gear classification ---\n\n")
cat("Q4. Given the monitoring gaps and ramp-up periods identified above, which years\n",
    "    and municipalities do you consider to have sufficiently consistent and\n",
    "    representative coverage to include in the metier analysis? Are there sampling\n",
    "    periods that should be excluded or treated with caution?\n\n")
cat("Q6. Manufahi records zero long line across all years, yet long line dominates\n",
    "    elsewhere on the south coast. Do Manufahi fishers use set lines at all? If yes,\n",
    "    how do enumerators decide whether to record a trip as hand line vs long line?\n\n")
cat("Q7. Viqueque 2018 records 248 hand line landings and zero long line. From 2019\n",
    "    onward, long line dominates and hand line drops to near-zero. Was this a\n",
    "    first-year recording inconsistency, or did gear use genuinely change between\n",
    "    2018 and 2019?\n\n")

cat("=============================================================\n")
cat("Q5, Q8–Q13 are in Scripts 2 and 3.\n")

