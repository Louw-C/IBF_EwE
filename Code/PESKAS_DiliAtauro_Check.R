# PESKAS_DiliAtauro_Check.R
# Cross-check — Dili and Atauro, the two municipalities used by Longobardi et al.
# (2026, Nature Food) to train their FNP k-means/XGBoost models.
#
# Purpose: Longobardi et al. restricted their nutrient-profile modelling to Dili
# and Atauro because these are "the most complete and reliable trip-level
# records." Their models depend heavily on gear and habitat as predictors. This
# script re-runs the same diagnostic checks used for the south coast
# (PESKAS_1/2/3) on Dili + Atauro, to test whether the gear/habitat recording
# issues found on the south coast (sabiki contamination, Deep vs Reef
# conflation, enumerator-driven habitat switches, coverage gaps) are also
# present in the two municipalities the published paper treats as clean.
#
# Input:  Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv  (READ ONLY)
#         Data/raw/Fisheries/Peskas groups_From Lore.csv          (READ ONLY)
# Output: Figures/PESKAS_DA_1_coverage_heatmap.png
#         Figures/PESKAS_DA_2_gear_taxon.png
#         Figures/PESKAS_DA_3_habitat_taxon.png
#         Figures/PESKAS_DA_4_habitat_over_time.png
# -----------------------------------------------------------------------


# ---- 1. Packages ----
library(tidyverse)
library(RColorBrewer)
library(patchwork)


# ---- 2. Load data ----

cpue <- read_csv(
  "Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv",
  show_col_types = FALSE
)

lookup <- read_csv(
  "Data/raw/Fisheries/Peskas groups_From Lore.csv",
  show_col_types = FALSE
)

cat("CPUE rows:", nrow(cpue), "\n")
cat("Lookup groups:", nrow(lookup), "\n")


# ---- 3. Filter to Dili and Atauro ----
# These are the two municipalities Longobardi et al. (2026) used for k-means
# clustering and XGBoost prediction of Fishery Nutrient Profiles (FNPs).

da_munis <- c("Dili", "Atauro")

da <- cpue |>
  filter(municipality %in% da_munis) |>
  mutate(year = as.integer(format(as.Date(landing_date), "%Y")))

cat("\nDili + Atauro rows:", nrow(da), "\n")
cat("Dili + Atauro unique landings:", n_distinct(da$landing_id), "\n")
cat("Year range:", min(da$year), "-", max(da$year), "\n")

# Same < 20 landing-event threshold rule used for the south coast: drop gears
# and habitats too sparse to show general patterns. Counted on all landings
# (catch = 0 and catch > 0).
gear_counts_all <- da |> distinct(landing_id, gear)    |> count(gear,    name = "n_landings")
hab_counts_all  <- da |> distinct(landing_id, habitat) |> count(habitat, name = "n_landings")
rare_gears <- gear_counts_all |> filter(n_landings < 20) |> pull(gear)
rare_habs  <- hab_counts_all  |> filter(n_landings < 20) |> pull(habitat)

cat("\nGears removed (< 20 landing events):\n")
gear_counts_all |> filter(n_landings < 20) |> print()
cat("Habitats removed (< 20 landing events):\n")
hab_counts_all |> filter(n_landings < 20) |> print()

if (length(rare_gears) > 0 || length(rare_habs) > 0) {
  n_before <- n_distinct(da$landing_id)
  da <- da |> filter(!gear %in% rare_gears, !habitat %in% rare_habs)
  cat("Dili + Atauro landings retained:", n_distinct(da$landing_id),
      "(removed", n_before - n_distinct(da$landing_id), ")\n\n")
}


# ---- 4. Coverage: landings by municipality x year x month ----
# Same diagnostic as south coast Step 1a — reveals monitoring gaps and
# ramp-up/collapse periods that would undermine any trend or metier analysis.

cat("\n=== Coverage: unique landings by municipality x year ===\n")
landings_year <- da |>
  distinct(landing_id, municipality, year) |>
  count(municipality, year, name = "n_landings")

all_year_cells <- expand_grid(municipality = da_munis, year = 2018:2025)
landings_year_full <- all_year_cells |>
  left_join(landings_year, by = c("municipality", "year")) |>
  mutate(n_landings = replace_na(n_landings, 0L))

landings_year_full |> pivot_wider(names_from = municipality, values_from = n_landings) |> print(n = 10)

month_labels <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

landings_month <- da |>
  mutate(month = as.integer(format(as.Date(landing_date), "%m"))) |>
  distinct(landing_id, municipality, year, month) |>
  count(municipality, year, month, name = "n_landings")

all_month_cells <- expand_grid(municipality = da_munis, year = 2018:2025, month = 1:12)

landings_month_full <- all_month_cells |>
  left_join(landings_month, by = c("municipality", "year", "month")) |>
  mutate(
    n_landings  = replace_na(n_landings, 0L),
    fill_value  = ifelse(n_landings == 0, NA_integer_, n_landings),
    label       = as.character(n_landings),
    text_colour = ifelse(n_landings > 200, "white", "grey20")
  )

p_da1 <- ggplot(landings_month_full,
                aes(x = factor(month, labels = month_labels),
                    y = factor(year, levels = rev(2018:2025)),
                    fill = fill_value)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_colour), size = 2.2, fontface = "bold") +
  facet_wrap(~municipality, ncol = 1) +
  scale_fill_gradient(low = "#e8f5e9", high = "#1b5e20", na.value = "grey85",
                      name = "Unique\nlandings") +
  scale_colour_identity() +
  labs(title = "Dili/Atauro check: unique landing events by year and month",
       subtitle = "Grey cells = no landings recorded.",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(), strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold"), plot.subtitle = element_text(size = 9, colour = "grey40"))

ggsave("Figures/PESKAS_DA_1_coverage_heatmap.png", p_da1, width = 9, height = 6, dpi = 300)
cat("Saved: Figures/PESKAS_DA_1_coverage_heatmap.png\n")

cat("\n--- FLAG: coverage anomalies ---\n")
cat("Dili: near-zero landings 2018-2019, spikes 2020-2022, then collapses to <100/year from 2023.\n")
cat("Atauro: rises steadily 2018-2022, then declines 2023-2025.\n")
cat("Both patterns mirror the kind of ramp-up/collapse anomalies flagged for the south coast\n")
cat("(Manufahi 2022 gap, Ainaro post-2023 absence, Covalima swings) - i.e. municipality-level\n")
cat("monitoring reliability is not stable over time even in the 'reliable' subset.\n")


# ---- 5. Gear coverage by municipality x year ----

cat("\n=== Gear composition ===\n")
gear_landings <- da |> distinct(landing_id, municipality, year, gear) |>
  count(municipality, year, gear, name = "n_landings")

n_da_landings <- n_distinct(da$landing_id)

cat("\nTotal landings by gear (% of all Dili+Atauro landings):\n")
gear_landings |>
  group_by(gear) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  arrange(desc(n_landings)) |>
  mutate(pct_total = round(n_landings / n_da_landings * 100, 1)) |>
  print()

cat("\nGear x municipality (% within municipality):\n")
gear_landings |>
  group_by(municipality, gear) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  group_by(municipality) |>
  mutate(pct_within_muni = round(n_landings / sum(n_landings) * 100, 1)) |>
  ungroup() |>
  arrange(municipality, desc(n_landings)) |>
  print(n = 20)


# ---- 6. Habitat coverage by municipality x year ----

cat("\n=== Habitat composition ===\n")
habitat_landings <- da |> distinct(landing_id, municipality, year, habitat) |>
  count(municipality, year, habitat, name = "n_landings")

cat("\nTotal landings by habitat (% of all Dili+Atauro landings):\n")
habitat_landings |>
  group_by(habitat) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  arrange(desc(n_landings)) |>
  mutate(pct_total = round(n_landings / n_da_landings * 100, 1)) |>
  print()

cat("\nHabitat x municipality (% within municipality):\n")
habitat_landings |>
  group_by(municipality, habitat) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  group_by(municipality) |>
  mutate(pct_within_muni = round(n_landings / sum(n_landings) * 100, 1)) |>
  ungroup() |>
  arrange(municipality, desc(n_landings)) |>
  print(n = 20)


# ---- 7. Build catch base (non-zero, split entries summed) ----

catch_base <- da |>
  filter(catch > 0) |>
  group_by(landing_id, municipality, year, gear, habitat, catch_taxon) |>
  summarise(catch_kg = sum(catch), .groups = "drop") |>
  left_join(lookup |> select(interagency_code, catch_name_en),
            by = c("catch_taxon" = "interagency_code"))

cat("\nLanding x taxon rows (non-zero, splits summed):", nrow(catch_base), "\n")
cat("Unique landings with any catch:", n_distinct(catch_base$landing_id), "\n")
cat("Unique taxa caught:", n_distinct(catch_base$catch_taxon), "\n")

n_gear_total <- da |> distinct(landing_id, gear) |> count(gear, name = "n_gear_total")
n_hab_total  <- da |> distinct(landing_id, habitat) |> count(habitat, name = "n_hab_total")

taxon_order <- catch_base |> count(catch_name_en, sort = TRUE) |> pull(catch_name_en)
hab_order   <- da |> distinct(landing_id, habitat) |> count(habitat, sort = TRUE) |> pull(habitat)

# Top 5 gears by volume — mirrors south coast's 3-gear approach but Dili/Atauro
# has meaningful volume in spear gun and seine net too (absent on south coast).
main_gears <- gear_counts_all |> filter(!gear %in% rare_gears) |>
  arrange(desc(n_landings)) |> slice_head(n = 5) |> pull(gear)
cat("\nMain gears for taxon frequency analysis:", paste(main_gears, collapse = ", "), "\n")


# ---- 8. Gear x taxon catch frequency + sabiki flag ----

gear_taxon <- catch_base |>
  filter(gear %in% main_gears) |>
  count(gear, catch_name_en, name = "n_landings") |>
  left_join(n_gear_total, by = "gear") |>
  mutate(pct_of_gear = round(n_landings / n_gear_total * 100, 1)) |>
  arrange(gear, desc(n_landings))

cat("\n=== Gear x taxon catch frequency (Dili+Atauro) ===\n")
for (g in main_gears) {
  cat("---", toupper(g), "(", n_gear_total$n_gear_total[n_gear_total$gear == g], "total landings ) ---\n")
  gear_taxon |> filter(gear == g) |> select(catch_name_en, n_landings, pct_of_gear) |>
    slice_head(n = 12) |> print()
  cat("\n")
}

cat("\n--- SABIKI FLAG CHECK: Mackerel scad / Sardines under long line and hand line ---\n")
gear_taxon |>
  filter(gear %in% c("long line", "hand line"),
         catch_name_en %in% c("Mackerel scad", "Sardines/pilchards")) |>
  select(gear, catch_name_en, n_landings, pct_of_gear) |>
  print()

# Long line vs hand line taxon profile correlation — mirrors south coast r = 0.77
ll_hl <- gear_taxon |>
  filter(gear %in% c("long line", "hand line")) |>
  select(gear, catch_name_en, pct_of_gear) |>
  pivot_wider(names_from = gear, values_from = pct_of_gear, values_fill = 0) |>
  rename(long_line = `long line`, hand_line = `hand line`)

cat("\nPearson correlation (long line vs hand line taxon frequencies), Dili+Atauro:",
    round(cor(ll_hl$long_line, ll_hl$hand_line), 3), "\n")
cat("(South coast equivalent: r = 0.77)\n")

# Gill net vs long line and gill net vs hand line — gill net is Dili/Atauro's
# dominant gear, so worth checking whether it's actually distinct
gn_ll <- gear_taxon |>
  filter(gear %in% c("gill net", "long line")) |>
  select(gear, catch_name_en, pct_of_gear) |>
  pivot_wider(names_from = gear, values_from = pct_of_gear, values_fill = 0)
cat("Pearson correlation (gill net vs long line taxon frequencies):",
    round(cor(gn_ll$`gill net`, gn_ll$`long line`), 3), "\n")


# ---- 9. Gear x taxon figure ----

gear_taxon_top <- catch_base |> filter(gear %in% main_gears) |>
  count(gear, catch_name_en, name = "n_landings") |>
  left_join(n_gear_total, by = "gear") |>
  mutate(pct = round(n_landings / n_gear_total * 100, 1))

top_taxa <- catch_base |> filter(gear %in% main_gears) |>
  count(catch_name_en, sort = TRUE) |> slice_head(n = 25) |> pull(catch_name_en)

grid_gt <- expand_grid(gear = main_gears, catch_name_en = top_taxa) |>
  left_join(gear_taxon_top, by = c("gear", "catch_name_en")) |>
  mutate(n_landings = replace_na(n_landings, 0L), pct = replace_na(pct, 0),
         label = ifelse(n_landings == 0, "", paste0(n_landings, "/", pct, "%")),
         text_col = ifelse(pct > 40, "white", "grey20"))

p_da2 <- ggplot(grid_gt, aes(x = factor(gear, levels = main_gears),
                             y = factor(catch_name_en, levels = rev(top_taxa)), fill = pct)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_col), size = 2.0, fontface = "bold") +
  scale_fill_gradient(low = "#f5f5f5", high = "#1a237e", limits = c(0, 100), name = "% of\nlandings") +
  scale_colour_identity() +
  scale_x_discrete(labels = str_to_title, position = "top") +
  labs(title = "Dili/Atauro check: taxon catch frequency by gear",
       subtitle = "% of landings where taxon was caught. Top 25 taxa shown.", x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(), axis.text.x = element_text(face = "bold"),
        plot.title = element_text(face = "bold"), plot.subtitle = element_text(size = 9, colour = "grey40"))

ggsave("Figures/PESKAS_DA_2_gear_taxon.png", p_da2, width = 8, height = 10, dpi = 300)
cat("Saved: Figures/PESKAS_DA_2_gear_taxon.png\n")


# ---- 10. Habitat x taxon catch frequency + Deep vs Reef check ----

hab_taxon <- catch_base |>
  count(habitat, catch_name_en, name = "n_landings") |>
  left_join(n_hab_total, by = "habitat") |>
  mutate(pct_of_habitat = round(n_landings / n_hab_total * 100, 1)) |>
  arrange(habitat, desc(n_landings))

cat("\n=== Habitat x taxon catch frequency (Dili+Atauro) ===\n")
for (h in hab_order) {
  n_tot <- n_hab_total$n_hab_total[n_hab_total$habitat == h]
  cat("---", toupper(h), "(", n_tot, "total landings ) ---\n")
  hab_taxon |> filter(habitat == h) |> select(catch_name_en, n_landings, pct_of_habitat) |>
    slice_head(n = 10) |> print()
  cat("\n")
}

deep_reef <- hab_taxon |>
  filter(habitat %in% c("Deep", "Reef")) |>
  select(habitat, catch_name_en, pct_of_habitat) |>
  pivot_wider(names_from = habitat, values_from = pct_of_habitat, values_fill = 0) |>
  mutate(diff = round(Deep - Reef, 1)) |>
  arrange(desc(abs(diff)))

cat("\n--- Deep vs Reef taxon profile comparison (Dili+Atauro) ---\n")
cat("Pearson correlation (Deep vs Reef taxon frequencies):",
    round(cor(deep_reef$Deep, deep_reef$Reef), 3), "\n")
cat("(South coast equivalent: high correlation reported, profiles near-identical)\n\n")
print(deep_reef, n = 30)

cat("\n--- Reef-obligate / shallow species appearing under 'Deep' (Dili+Atauro) ---\n")
reef_obligate <- c("Parrotfish", "Surgeonfish", "Wrasse", "Soldierfish", "Fusilier",
                   "Moray", "Crab", "Octopus", "Shrimp", "Milkfish")
hab_taxon |>
  filter(habitat == "Deep", catch_name_en %in% reef_obligate) |>
  select(catch_name_en, n_landings, pct_of_habitat) |>
  print()

cat("\n--- Small pelagics appearing under 'Reef' (Dili+Atauro) ---\n")
hab_taxon |>
  filter(habitat == "Reef", catch_name_en %in% c("Sardines/pilchards", "Mackerel scad")) |>
  select(catch_name_en, n_landings, pct_of_habitat) |>
  print()


# ---- 11. Habitat x taxon figure ----

grid_ht <- expand_grid(habitat = hab_order, catch_name_en = top_taxa) |>
  left_join(hab_taxon |> select(habitat, catch_name_en, n_landings, pct_of_habitat),
            by = c("habitat", "catch_name_en")) |>
  mutate(n_landings = replace_na(n_landings, 0L), pct_of_habitat = replace_na(pct_of_habitat, 0),
         label = ifelse(n_landings == 0, "", paste0(n_landings, "/", pct_of_habitat, "%")),
         text_col = ifelse(pct_of_habitat > 40, "white", "grey20"))

p_da3 <- ggplot(grid_ht, aes(x = factor(habitat, levels = hab_order),
                             y = factor(catch_name_en, levels = rev(top_taxa)), fill = pct_of_habitat)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_col), size = 2.0, fontface = "bold") +
  scale_fill_gradient(low = "#f5f5f5", high = "#1a237e", limits = c(0, 100), name = "% of\nlandings") +
  scale_colour_identity() +
  scale_x_discrete(labels = str_to_title, position = "top") +
  labs(title = "Dili/Atauro check: taxon catch frequency by habitat",
       subtitle = "% of landings where taxon was caught. Top 25 taxa shown.", x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(), axis.text.x = element_text(face = "bold"),
        plot.title = element_text(face = "bold"), plot.subtitle = element_text(size = 9, colour = "grey40"))

ggsave("Figures/PESKAS_DA_3_habitat_taxon.png", p_da3, width = 8, height = 10, dpi = 300)
cat("Saved: Figures/PESKAS_DA_3_habitat_taxon.png\n")


# ---- 12. Gear x habitat combinations ----

gear_hab <- da |> distinct(landing_id, gear, habitat) |>
  count(gear, habitat, name = "n_landings") |>
  left_join(n_gear_total, by = "gear") |>
  mutate(pct_of_gear = round(n_landings / n_gear_total * 100, 1)) |>
  arrange(gear, desc(n_landings))

cat("\n=== Gear x habitat (Dili+Atauro) ===\n")
print(gear_hab, n = 60)


# ---- 13. Habitat composition over time by municipality ----
# Same diagnostic as south coast Step 3d — checks for abrupt habitat-label
# switches consistent with enumerator changes rather than real behaviour.

hab_year_muni <- da |>
  distinct(landing_id, habitat, municipality, year) |>
  count(habitat, municipality, year, name = "n_landings") |>
  group_by(municipality, year) |>
  mutate(pct = round(n_landings / sum(n_landings) * 100, 1)) |>
  ungroup()

cat("\n=== Habitat composition over time by municipality ===\n")
hab_year_muni |> arrange(municipality, year, desc(n_landings)) |> print(n = 100)

hab_time_grid <- expand_grid(habitat = hab_order, municipality = da_munis, year = 2018:2025) |>
  left_join(hab_year_muni, by = c("habitat", "municipality", "year")) |>
  mutate(n_landings = replace_na(n_landings, 0L), pct = replace_na(pct, 0))

n_habs <- length(hab_order)
hab_colors <- setNames(brewer.pal(max(n_habs, 3), "Set2")[seq_len(n_habs)], hab_order)

p_da4 <- hab_time_grid |>
  mutate(habitat = factor(habitat, levels = rev(hab_order)), year = factor(year)) |>
  ggplot(aes(x = year, y = pct, fill = habitat)) +
  geom_col(width = 0.8, position = "stack") +
  facet_wrap(~municipality, ncol = 1) +
  scale_fill_manual(values = hab_colors, name = "Habitat") +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0), labels = \(x) paste0(x, "%")) +
  labs(title = "Dili/Atauro check: habitat composition over time",
       subtitle = "Sudden shifts within a municipality suggest enumerator/protocol change, not real behaviour.",
       x = NULL, y = "% of landing events") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold"), plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(size = 9, colour = "grey40"))

ggsave("Figures/PESKAS_DA_4_habitat_over_time.png", p_da4, width = 8, height = 7, dpi = 300)
cat("Saved: Figures/PESKAS_DA_4_habitat_over_time.png\n")


# ---- 14. Summary comparison to south coast findings ----

cat("\n========== SUMMARY: DILI/ATAURO vs SOUTH COAST DATA QUALITY ==========\n\n")
cat("1. SABIKI CONTAMINATION\n")
cat("   South coast: Mackerel scad 30% (LL) / 48% (HL); Sardines 24% (LL) / 21% (HL)\n")
cat("   Dili+Atauro: see 'SABIKI FLAG CHECK' output above for equivalent figures\n\n")
cat("2. LONG LINE vs HAND LINE OVERLAP\n")
cat("   South coast: Pearson r = 0.77\n")
cat("   Dili+Atauro: see correlation output above\n\n")
cat("3. DEEP vs REEF OVERLAP\n")
cat("   South coast: highly correlated, ecologically indistinguishable\n")
cat("   Dili+Atauro: see correlation output above\n\n")
cat("4. REEF-OBLIGATE SPECIES UNDER 'DEEP'\n")
cat("   South coast: Parrotfish, Surgeonfish, Wrasse, Soldierfish, Fusilier, Moray,\n")
cat("   Crab, Octopus, Shrimp, Milkfish all appear under Deep at non-trivial rates\n")
cat("   Dili+Atauro: see output above\n\n")
cat("5. COVERAGE STABILITY\n")
cat("   South coast: Manufahi 2022 gap, Ainaro post-2023 absence, Covalima swings\n")
cat("   Dili+Atauro: see coverage flag above (Dili near-absent 2018-19 and post-2023)\n")
cat("========================================================================\n")
