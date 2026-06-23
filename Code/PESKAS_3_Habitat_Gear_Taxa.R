# PESKAS_3_Habitat_Gear_Taxa.R
# Phase 3 — Habitat × gear × taxon analysis, south coast Timor-Leste
#
# Assesses whether the habitat field is ecologically interpretable (fishing
# ground) or records the boat's departure point. Habitat must be meaningful
# before it can be used as a third metier dimension or linked to EwE
# functional group habitat assignments.
#
# Input:  Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv  (READ ONLY)
#         Data/raw/Fisheries/Peskas groups_From Lore.csv          (READ ONLY)
# Output: Figures/PESKAS_3a_habitat_municipality.png
#         Figures/PESKAS_3b_habitat_taxon.png
#         Figures/PESKAS_3c_gear_habitat.png
#         Figures/PESKAS_3d_habitat_over_time.png
# -----------------------------------------------------------------------


# ---- 1. Packages ----
library(tidyverse)
library(RColorBrewer)
library(patchwork)


# ---- 2. Load data ----
# - cpue: one row per taxon slot per landing (including zeros)
# - lookup: maps interagency_code to full English names; join key = interagency_code

cpue <- read_csv(
  "Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv",
  show_col_types = FALSE
)

lookup <- read_csv(
  "Data/raw/Fisheries/Peskas groups_From Lore.csv",
  show_col_types = FALSE
)

cat("CPUE rows:", nrow(cpue), "\n")        # Expected: 221,258
cat("Lookup groups:", nrow(lookup), "\n")  # Expected: 59


# ---- 3. Filter and build catch base ----
# - Filter to south coast municipalities
# - Exclude zero-catch rows; sum split entries (same taxon 2-3× per landing)
# - Join lookup for full taxon names — raw codes never used in output
# - Pre-compute habitat order and denominators used by all later sections

sc_munis <- c("Covalima", "Ainaro", "Manufahi", "Viqueque")

sc <- cpue |>
  filter(municipality %in% sc_munis) |>
  mutate(year = as.integer(format(as.Date(landing_date), "%Y")))

catch_base <- sc |>
  filter(catch > 0) |>
  group_by(landing_id, municipality, year, gear, habitat, catch_taxon) |>
  summarise(catch_kg = sum(catch), .groups = "drop") |>
  left_join(
    lookup |> select(interagency_code, catch_name_en),
    by = c("catch_taxon" = "interagency_code")
  )

cat("\nLanding × taxon rows (non-zero, splits summed):", nrow(catch_base), "\n")
cat("Unique landings with any catch:", n_distinct(catch_base$landing_id), "\n")
# Expected: 11,115
cat("Unique taxa caught:", n_distinct(catch_base$catch_taxon), "\n")
# Expected: 44

# Taxon order: most frequently caught first (consistent with Script 2 figures)
taxon_order <- catch_base |>
  count(catch_name_en, sort = TRUE) |>
  pull(catch_name_en)

# Habitat order: most frequent first; used for axes and console loop order
hab_order <- sc |>
  distinct(landing_id, habitat) |>
  count(habitat, sort = TRUE) |>
  pull(habitat)

cat("\nHabitat types (all sc landings, most to least frequent):\n")
sc |>
  distinct(landing_id, habitat) |>
  count(habitat, name = "n_landings", sort = TRUE) |>
  mutate(pct = round(n_landings / sum(n_landings) * 100, 1)) |>
  print()

# Denominators: all sc landings per habitat / gear (incl. zero-catch trips)
# Consistent with Script 2 approach — denominator = all trips, not just those with catch
n_hab_total <- sc |>
  distinct(landing_id, habitat) |>
  count(habitat, name = "n_hab_total")

n_gear_total <- sc |>
  distinct(landing_id, gear) |>
  count(gear, name = "n_gear_total")

main_gears <- c("long line", "gill net", "hand line")


# ---- 4. Step 3a: Habitat coverage by municipality ----
# - Landing events per habitat × municipality, expressed as % within municipality
# - Known flag: "Deep" expected to dominate (~88% of sc records) — ecologically
#   inconsistent with a largely non-motorised nearshore fishery where most boats
#   fish within 5 km of shore (López-Angarita et al. 2020)
# - Key diagnostic: if "Deep" dominates even for gears and municipalities that
#   are clearly nearshore, it is likely a departure-point label or default value

hab_muni <- sc |>
  distinct(landing_id, habitat, municipality) |>
  count(habitat, municipality, name = "n_landings") |>
  group_by(municipality) |>
  mutate(pct = round(n_landings / sum(n_landings) * 100, 1)) |>
  ungroup()

cat("\n=== 3a: Landing events by habitat × municipality ===\n")
cat("% = share of that municipality's total landing events.\n\n")
hab_muni |>
  arrange(municipality, desc(n_landings)) |>
  print(n = 60)

cat("\nHabitat totals across all south coast municipalities:\n")
hab_muni |>
  group_by(habitat) |>
  summarise(n_landings = sum(n_landings), .groups = "drop") |>
  mutate(pct = round(n_landings / sum(n_landings) * 100, 1)) |>
  arrange(desc(n_landings)) |>
  print()


# ---- 5. Step 3a figure: Habitat × municipality heatmap ----
# Habitat on y (most frequent at top), municipality on x.
# Colour = % of that municipality's landing events; labels = "n / pct%".
# Absent combinations shown as empty white cells (not grey — all municipalities
# have a habitat field for every landing, so absence means zero landings there).

hab_muni_grid <- expand_grid(
  habitat      = hab_order,
  municipality = sc_munis
) |>
  left_join(hab_muni, by = c("habitat", "municipality")) |>
  mutate(
    n_landings = replace_na(n_landings, 0L),
    pct        = replace_na(pct, 0),
    label = case_when(
      n_landings == 0 ~ "",
      n_landings <  5 ~ paste0("<5 / ", pct, "%"),
      TRUE            ~ paste0(n_landings, " / ", pct, "%")
    ),
    text_col = ifelse(pct > 50, "white", "grey20")
  )

p3a <- hab_muni_grid |>
  mutate(habitat = factor(habitat, levels = rev(hab_order))) |>
  ggplot(aes(x = municipality, y = habitat, fill = pct)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = label, colour = text_col), size = 2.8, fontface = "bold") +
  scale_fill_gradient(low = "#e3f2fd", high = "#0d47a1",
                      limits = c(0, 100), name = "% of\nlandings") +
  scale_colour_identity() +
  labs(
    x        = NULL,
    y        = NULL,
    title    = "Step 3a: Habitat composition by municipality",
    subtitle = paste(
      "% of landing events per municipality. Numbers = landing counts.",
      "Flag: 'Deep' dominance across all municipalities in a largely non-motorised nearshore fishery.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid      = element_blank(),
    axis.text.x     = element_text(size = 9, face = "bold"),
    axis.text.y     = element_text(size = 9),
    plot.title      = element_text(face = "bold", size = 11),
    plot.subtitle   = element_text(size = 9, colour = "grey40"),
    legend.position = "right"
  )

ggsave("Figures/PESKAS_3a_habitat_municipality.png",
       p3a, width = 8, height = 5, dpi = 300)
cat("Saved: Figures/PESKAS_3a_habitat_municipality.png\n")


# ---- 6. Step 3b: Habitat × taxon catch frequency ----
# - pct_of_habitat = % of all landings in each habitat that caught each taxon
# - Denominator: n_hab_total — all sc landings per habitat, incl. zero-catch trips
# - Two sets of plausibility flags:
#   (a) Cross-habitat flags — implausible if habitat = fishing ground, not departure:
#       * Small pelagics (Sardines, Mackerel scad) under "Reef"
#       * Demersal reef fish (Snapper, Grouper, Emperor) under "Beach"
#       * Open-water pelagics (Tuna/Bonito) under "Mangrove" or "Seagrass"
#   (b) Deep-specific flags — reef-associated or shallow species under "Deep"
#       suggests "Deep" does not mean offshore open water:
#       * Parrotfish, Surgeonfish, Wrasse, Soldierfish, Fusilier, Moray — all
#         reef-obligate or reef-associated; cannot be caught offshore at depth
#       * Crab, Octopus, Shrimp — benthic intertidal/shallow; not deep-water
#       * Milkfish — estuarine/coastal; not offshore deep
# - Deep vs Reef profile comparison: if the taxon frequency profiles of "Deep"
#   and "Reef" are highly correlated, enumerators are not distinguishing between
#   the two habitat types — the labels are being used interchangeably

hab_taxon <- catch_base |>
  count(habitat, catch_name_en, name = "n_landings") |>
  left_join(n_hab_total, by = "habitat") |>
  mutate(pct_of_habitat = round(n_landings / n_hab_total * 100, 1)) |>
  arrange(habitat, desc(n_landings))

cat("\n=== 3b: Catch frequency by habitat × taxon ===\n")
cat("% = landings in that habitat where taxon was caught.\n\n")
for (h in hab_order) {
  n_tot <- n_hab_total$n_hab_total[n_hab_total$habitat == h]
  cat("---", toupper(h), "(", n_tot, "total landings ) ---\n")
  hab_taxon |>
    filter(habitat == h) |>
    select(catch_name_en, n_landings, pct_of_habitat) |>
    print(n = 50)
  cat("\n")
}

priority_flags_3b <- tibble(
  habitat       = c(
    # Reef — open-water species imply habitat = departure zone
    "Reef",  "Reef",
    # Beach — demersal reef fish imply very shallow catch or departure label
    "Beach", "Beach", "Beach",
    # Mangrove / Seagrass — open-water pelagics in nearshore habitats
    "Mangrove",                    "Seagrass",
    # Deep — reef-obligate or shallow species; inconsistent with offshore deep water
    "Deep", "Deep", "Deep", "Deep", "Deep",
    "Deep", "Deep", "Deep", "Deep", "Deep"
  ),
  catch_name_en = c(
    "Sardines/pilchards", "Mackerel scad",
    "Snapper/seaperch",   "Grouper", "Emperor",
    "Tuna/Bonito/Other Mackerel", "Tuna/Bonito/Other Mackerel",
    "Parrotfish", "Surgeonfish", "Wrasse", "Soldierfish", "Fusilier",
    "Moray",      "Crab",        "Octopus", "Shrimp",     "Milkfish"
  ),
  reason = c(
    "Open-water schooler — Reef catch implies habitat is launch site, not fishing ground",
    "Planktivore — same as above",
    "Benthic reef fish — Beach catch implies very shallow water or a departure label",
    "Same as above",
    "Same as above",
    "Open-water pelagic — Mangrove habitat is ecologically implausible",
    "Open-water pelagic — Seagrass habitat is ecologically implausible",
    "Reef-obligate herbivore — cannot be caught in open offshore deep water",
    "Shallow reef herbivore — same as above",
    "Reef-associated — rarely caught far from reef structure",
    "Shallow reef cave dweller — offshore depth catch is implausible",
    "Reef-associated schooler — tied to reef structure, not offshore deep water",
    "Reef crevice predator — does not inhabit open deep water",
    "Benthic intertidal/shallow — not an offshore species",
    "Intertidal/shallow reef — not caught in open deep water",
    "Benthic intertidal/shallow — not an offshore deep-water species",
    "Estuarine/coastal species — not found in offshore deep water"
  )
)

cat("--- Ecological plausibility flags ---\n")
print(priority_flags_3b, width = 120)

cat("\nObserved frequencies for flagged combinations:\n")
hab_taxon |>
  semi_join(priority_flags_3b, by = c("habitat", "catch_name_en")) |>
  arrange(habitat, desc(pct_of_habitat)) |>
  select(habitat, catch_name_en, n_landings, pct_of_habitat) |>
  print(n = 40)

# Deep vs Reef profile comparison
# If these two habitats are used interchangeably, their taxon frequency
# profiles will be highly correlated — the same species appear at similar
# rates in both, with no meaningful ecological separation between them.
cat("\n--- Deep vs Reef taxon profile comparison ---\n")
cat("High Pearson correlation = profiles are ecologically indistinguishable;\n",
    "enumerators are not consistently distinguishing these two habitat types.\n\n")

deep_reef <- hab_taxon |>
  filter(habitat %in% c("Deep", "Reef")) |>
  select(habitat, catch_name_en, pct_of_habitat) |>
  pivot_wider(names_from = habitat, values_from = pct_of_habitat,
              values_fill = 0) |>
  mutate(diff = round(Deep - Reef, 1)) |>
  arrange(desc(abs(diff)))

cat("Pearson correlation (Deep vs Reef taxon frequencies):",
    round(cor(deep_reef$Deep, deep_reef$Reef), 3), "\n\n")
cat("Per-taxon comparison (largest absolute differences first):\n")
print(deep_reef, n = 50)


# ---- 7. Step 3b figure: Habitat × taxon heatmap ----
# Habitats on x (frequency order, left to right), taxa on y (same order as
# Script 2 figures, most frequent at top). Single blue gradient — all habitats
# share the same metric so per-habitat colours are unnecessary.
# Habitat labels include total landing count below habitat name.

hab_labels <- n_hab_total |>
  mutate(label = paste0(habitat, "\nn = ", format(n_hab_total, big.mark = ","))) |>
  select(habitat, label) |>
  deframe()

hab_taxon_grid <- expand_grid(
  habitat       = hab_order,
  catch_name_en = taxon_order
) |>
  left_join(
    hab_taxon |> select(habitat, catch_name_en, n_landings, pct_of_habitat),
    by = c("habitat", "catch_name_en")
  ) |>
  mutate(
    n_landings     = replace_na(n_landings, 0L),
    pct_of_habitat = replace_na(pct_of_habitat, 0),
    label = case_when(
      n_landings == 0 ~ "",
      n_landings <  5 ~ paste0("<5 / ", pct_of_habitat, "%"),
      TRUE            ~ paste0(n_landings, " / ", pct_of_habitat, "%")
    ),
    text_col = ifelse(pct_of_habitat > 40, "white", "grey20")
  )

p3b <- hab_taxon_grid |>
  mutate(
    catch_name_en = factor(catch_name_en, levels = rev(taxon_order)),
    habitat       = factor(habitat,       levels = hab_order)
  ) |>
  ggplot(aes(x = habitat, y = catch_name_en, fill = pct_of_habitat)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = label, colour = text_col), size = 1.9, fontface = "bold") +
  scale_fill_gradient(low = "#f5f5f5", high = "#1a237e",
                      limits = c(0, 100), name = "% of\nlandings") +
  scale_colour_identity() +
  scale_x_discrete(labels = hab_labels) +
  labs(
    x        = NULL,
    y        = NULL,
    title    = "Step 3b: Taxon catch frequency by habitat",
    subtitle = paste(
      "% of landings in each habitat where taxon was caught. Numbers = landing counts.",
      "All values are catch frequencies, not catch sizes.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid      = element_blank(),
    axis.text.x     = element_text(size = 8, face = "bold"),
    axis.text.y     = element_text(size = 8),
    plot.title      = element_text(face = "bold", size = 11),
    plot.subtitle   = element_text(size = 9, colour = "grey40"),
    legend.position = "right"
  )

p3b

ggsave("Figures/PESKAS_3b_habitat_taxon.png",
       p3b, width = 10, height = 13, dpi = 300)
cat("Saved: Figures/PESKAS_3b_habitat_taxon.png\n")


# ---- 8. Step 3c: Gear × habitat combinations ----
# - Count unique landing events per gear × habitat; % = share of gear's total landings
# - Implausible combinations pre-specified and checked against observed data
# - Also tests whether habitat separates the main gears — if long line and hand
#   line have identical habitat profiles, habitat adds no discriminating power
#   as a metier dimension

gear_hab <- sc |>
  distinct(landing_id, gear, habitat) |>
  count(gear, habitat, name = "n_landings") |>
  left_join(n_gear_total, by = "gear") |>
  mutate(pct_of_gear = round(n_landings / n_gear_total * 100, 1)) |>
  arrange(gear, desc(n_landings))

cat("\n=== 3c: Landing events by gear × habitat ===\n")
cat("% = share of that gear's total landings in each habitat.\n\n")
print(gear_hab, n = 80)

implausible_3c <- tribble(
  ~gear,               ~habitat, ~reason,
  "beach seine",       "Deep",   "Benthic sweep gear — incompatible with deep or offshore water",
  "long line",         "Beach",  "Offshore bottom-set gear — beach deployment is unusual",
  "manual collection", "Deep",   "Intertidal gleaning — 'Deep' habitat is ecologically implausible",
  "spear gun",         "Deep",   "Freediving gear — effective depth range is very limited"
)

cat("\nPredefined implausible gear × habitat combinations:\n")
print(implausible_3c, width = 100)

cat("\nObserved counts for flagged combinations:\n")
gear_hab |>
  semi_join(implausible_3c, by = c("gear", "habitat")) |>
  select(gear, habitat, n_landings, pct_of_gear) |>
  print()


# ---- 9. Step 3c figure: Gear × habitat heatmap ----
# All gears × all habitats. Colour = % of gear's total landings in that habitat;
# grey = combination not observed. Gear labels title-cased on x-axis.

all_gears <- sort(unique(sc$gear))

gear_hab_grid <- expand_grid(gear = all_gears, habitat = hab_order) |>
  left_join(n_gear_total, by = "gear") |>
  left_join(
    gear_hab |> select(gear, habitat, n_landings, pct_of_gear),
    by = c("gear", "habitat")
  ) |>
  mutate(
    fill_pct   = ifelse(is.na(n_landings), NA_real_, replace_na(pct_of_gear, 0)),
    n_landings = replace_na(n_landings, 0L),
    label = case_when(
      is.na(fill_pct) ~ "",
      n_landings == 0 ~ "",
      n_landings <  5 ~ paste0("<5 / ", fill_pct, "%"),
      TRUE            ~ paste0(n_landings, " / ", fill_pct, "%")
    ),
    text_col = ifelse(!is.na(fill_pct) & fill_pct > 50, "white", "grey20")
  )

p3c <- gear_hab_grid |>
  mutate(
    gear    = factor(gear,    levels = sort(all_gears)),
    habitat = factor(habitat, levels = rev(hab_order))
  ) |>
  ggplot(aes(x = gear, y = habitat, fill = fill_pct)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = label, colour = text_col), size = 2.4, fontface = "bold") +
  scale_fill_gradient(low = "#fff3e0", high = "#e65100",
                      limits = c(0, 100), na.value = "grey80",
                      name = "% of\ngear\nlandings") +
  scale_colour_identity() +
  scale_x_discrete(labels = str_to_title) +
  labs(
    x        = NULL,
    y        = NULL,
    title    = "Step 3c: Landing events by gear × habitat",
    subtitle = paste(
      "% of each gear's total landings recorded in each habitat. Grey = combination not observed.",
      "Flag: deep-water gear at 'Beach'; intertidal gear at 'Deep'.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid      = element_blank(),
    axis.text.x     = element_text(angle = 30, hjust = 1, size = 8, face = "bold"),
    axis.text.y     = element_text(size = 9),
    plot.title      = element_text(face = "bold", size = 11),
    plot.subtitle   = element_text(size = 9, colour = "grey40"),
    legend.position = "right"
  )

ggsave("Figures/PESKAS_3c_gear_habitat.png",
       p3c, width = 9, height = 6, dpi = 300)
cat("Saved: Figures/PESKAS_3c_gear_habitat.png\n")


# ---- 10. Step 3d: Habitat composition over time by municipality ----
# - Landing events per habitat × municipality × year as % within municipality × year
# - Stacked bar (x = year, fill = habitat) faceted by municipality — direct
#   analog of Script 1b gear coverage plot
# - Diagnostic: stable proportions year-over-year = consistent recording;
#   a sudden shift in "Deep" or "Reef" share within a municipality points to
#   an enumerator change or protocol change, not a real behavioural shift
# - Known context: Manufahi 2022 = zero landings (complete monitoring gap);
#   Ainaro absent from 2024; Covalima 2024 has anomalous row counts

hab_year_muni <- sc |>
  distinct(landing_id, habitat, municipality, year) |>
  count(habitat, municipality, year, name = "n_landings") |>
  group_by(municipality, year) |>
  mutate(pct = round(n_landings / sum(n_landings) * 100, 1)) |>
  ungroup()

cat("\n=== 3d: Habitat composition over time by municipality ===\n")
cat("% = share of that municipality × year's landing events per habitat.\n\n")
hab_year_muni |>
  arrange(municipality, year, desc(n_landings)) |>
  print(n = 120)

# Flag 1: Ainaro Reef → Deep reclassification
# Ainaro is ~99% Reef in 2019, transitions through 2020, then 100% Deep from
# 2021 onwards with no Reef at all. This is a hard switch, not a gradual
# ecological change — almost certainly driven by an enumerator change.
cat("\n--- FLAG: Ainaro habitat reclassification (2019 → 2021) ---\n")
hab_year_muni |>
  filter(municipality == "Ainaro") |>
  select(year, habitat, n_landings, pct) |>
  arrange(year, desc(n_landings)) |>
  print(n = 20)

# Flag 2: Viqueque FAD disappearance (2018 → 2019)
# FAD accounted for 62.5% of Viqueque landings in 2018, then dropped to 1.1%
# in 2019 and near-zero thereafter. 2018 Viqueque is already flagged in Phase 1
# for gear (all hand line, zero long line). FAD-associated catch in 2018 will
# inflate pelagic species (tuna, large jacks) relative to all later years —
# 2018 should not be used as a baseline year for Viqueque.
cat("\n--- FLAG: Viqueque FAD disappearance (2018 → 2019) ---\n")
hab_year_muni |>
  filter(municipality == "Viqueque") |>
  select(year, habitat, n_landings, pct) |>
  arrange(year, desc(n_landings)) |>
  print(n = 30)

# Complete grid: all habitat × municipality × year combinations
# Missing cells = habitat not recorded in that year (show as 0)
all_years <- sort(unique(sc$year))

hab_time_grid <- expand_grid(
  habitat      = hab_order,
  municipality = sc_munis,
  year         = all_years
) |>
  left_join(hab_year_muni, by = c("habitat", "municipality", "year")) |>
  mutate(
    n_landings = replace_na(n_landings, 0L),
    pct        = replace_na(pct, 0)
  )

# Habitat colour palette — qualitative; up to 8 categories (Set2)
n_habs     <- length(hab_order)
hab_colors <- setNames(
  brewer.pal(max(n_habs, 3), "Set2")[seq_len(n_habs)],
  hab_order
)

p3d <- hab_time_grid |>
  mutate(
    habitat = factor(habitat, levels = rev(hab_order)),
    year    = factor(year)
  ) |>
  ggplot(aes(x = year, y = pct, fill = habitat)) +
  geom_col(width = 0.8, position = "stack") +
  facet_wrap(~municipality, ncol = 2) +
  scale_fill_manual(values = hab_colors, name = "Habitat") +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0),
                     labels = \(x) paste0(x, "%")) +
  labs(
    x        = NULL,
    y        = "% of landing events",
    title    = "Step 3d: Habitat composition over time by municipality",
    subtitle = paste(
      "% of each year's landing events recorded in each habitat. Stable proportions = consistent recording.",
      "Sudden shifts within a municipality indicate enumerator or protocol change, not real behaviour.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.x        = element_text(angle = 45, hjust = 1, size = 8),
    strip.text         = element_text(face = "bold", size = 10),
    plot.title         = element_text(face = "bold", size = 11),
    plot.subtitle      = element_text(size = 9, colour = "grey40"),
    legend.position    = "right"
  )

ggsave("Figures/PESKAS_3d_habitat_over_time.png",
       p3d, width = 10, height = 8, dpi = 300)
cat("Saved: Figures/PESKAS_3d_habitat_over_time.png\n")


# ---- 11. Step 3e: Team question list ----
# Compiled questions for Lore (Lorenzo Longobardi, PESKAS team).
# Format per question: What we found → Figure → Question → Why it matters.
# These complement the Phase 1 questions (Script 1, Section 8) and Phase 2
# questions (Script 2, Section 7).

cat("\n=== PHASE 3 TEAM QUESTIONS ===\n\n")

cat("Q1. What does 'Deep' mean in the PESKAS habitat field?\n",
    "   WHAT WE FOUND: 'Deep' accounts for the large majority of south coast\n",
    "   landing events across all four municipalities and all gear types. More\n",
    "   importantly, a consistent set of reef-obligate and shallow-water species\n",
    "   appear under 'Deep' at non-trivial frequencies: Parrotfish, Surgeonfish,\n",
    "   Wrasse, Soldierfish, Fusilier, Moray, Crab, Octopus, Shrimp, and Milkfish.\n",
    "   None of these are offshore deep-water species. Their presence under 'Deep'\n",
    "   is only ecologically coherent if 'Deep' means something other than open\n",
    "   offshore water — for example, reef edge, rocky bottom below the reef crest,\n",
    "   or simply 'not beach/mangrove'.\n",
    "   FIGURE: PESKAS_3b_habitat_taxon.png\n",
    "   QUESTION: Does 'Deep' refer to (a) water depth fished (and if so, what\n",
    "   threshold depth?), (b) distance from shore, (c) substrate type such as\n",
    "   rocky/sandy bottom below the reef crest, or (d) a residual default used\n",
    "   when the fishing ground does not fit Reef, Beach, Mangrove, or Seagrass?\n",
    "   WHY IT MATTERS: The answer determines whether 'Deep' can be used to\n",
    "   separate demersal from pelagic metiers and to link catch groups to the\n",
    "   correct EwE functional group habitat assignments. If 'Deep' is a residual\n",
    "   category, it carries no ecological information.\n\n")

cat("Q2. Are 'Deep' and 'Reef' being used interchangeably by enumerators?\n",
    "   WHAT WE FOUND: The Pearson correlation between the taxon frequency\n",
    "   profiles of 'Deep' and 'Reef' landings is printed above (see console\n",
    "   output: 'Deep vs Reef taxon profile comparison'). A high correlation\n",
    "   (>0.8) means that broadly the same species appear at broadly the same\n",
    "   rates in both habitats — the two labels are not producing ecologically\n",
    "   distinguishable catch profiles. Reef-obligate species (Parrotfish,\n",
    "   Surgeonfish, Wrasse) appear under 'Deep'; open-water species (Mackerel\n",
    "   scad, Sardines) appear under 'Reef'. Neither pattern is consistent with\n",
    "   the habitat labels meaning what they say.\n",
    "   FIGURE: PESKAS_3b_habitat_taxon.png\n",
    "   QUESTION: Is there a formal definition of 'Deep' vs 'Reef' in the PESKAS\n",
    "   enumerator protocol? If so, how is the distinction communicated and\n",
    "   verified in the field? Is it possible that individual enumerators apply\n",
    "   these labels differently?\n",
    "   WHY IT MATTERS: If 'Deep' and 'Reef' cannot be distinguished by their\n",
    "   catch profiles, combining them into a single 'non-beach' category may be\n",
    "   more honest than treating them as separate habitat types in the metier\n",
    "   classification or EwE model.\n\n")

cat("Q3. Is 'Reef' the launch site or the fishing ground?\n",
    "   WHAT WE FOUND: Sardines/pilchards and Mackerel scad appear in 'Reef'\n",
    "   habitat landings. Both are open-water schooling species that do not\n",
    "   associate with reef structure as a primary habitat.\n",
    "   FIGURE: PESKAS_3b_habitat_taxon.png\n",
    "   QUESTION: When a landing is recorded as 'Reef' and the catch includes\n",
    "   Sardines or Mackerel scad, did the boat fish over reef structure, or did\n",
    "   it depart from a reef-adjacent landing site and then fish in open water?\n",
    "   WHY IT MATTERS: If 'Reef' is a departure zone, small-pelagic catches under\n",
    "   'Reef' are recording artefacts — the habitat field cannot be used to assign\n",
    "   those catch groups to EwE reef functional groups.\n\n")

cat("Q4. Are demersal species under 'Beach' caught inshore, or from boats that\n",
    "   departed from a beach landing site and fished at depth?\n",
    "   WHAT WE FOUND: Snapper/seaperch, Grouper, and Emperor appear in 'Beach'\n",
    "   habitat landings. These are benthic reef fish that normally live at depth\n",
    "   and are not typical beach-seine or intertidal catch.\n",
    "   FIGURE: PESKAS_3b_habitat_taxon.png\n",
    "   QUESTION: Does 'Beach' mean (a) the boat fished in a shallow nearshore\n",
    "   sandy-beach zone, (b) the enumerator recorded the beach as the departure\n",
    "   point, or (c) a beach seine was used?\n",
    "   WHY IT MATTERS: Determines whether 'Beach' landings with demersal taxa\n",
    "   should be assigned to nearshore or offshore EwE functional group habitats.\n\n")

cat("Q5. Why does manual collection (gleaning) appear under 'Deep' habitat?\n",
    "   WHAT WE FOUND: Manual collection records appear under 'Deep' habitat in\n",
    "   some south coast municipality × year combinations. Gleaning is an\n",
    "   intertidal or very shallow-water activity.\n",
    "   FIGURE: PESKAS_3c_gear_habitat.png\n",
    "   QUESTION: Are any of these genuine free-diving operations (e.g. for sea\n",
    "   cucumber at depth), or is 'Deep' used as a default when the enumerator\n",
    "   is uncertain or the habitat field is completed by a supervisor after the\n",
    "   fact?\n",
    "   WHY IT MATTERS: If 'Deep' is a data-entry default rather than a recorded\n",
    "   observation, its high frequency across all gear types reflects recording\n",
    "   behaviour, not actual habitat use — which would invalidate habitat-based\n",
    "   metier splitting entirely.\n\n")

cat("Q6. What explains the abrupt habitat reclassification in Ainaro and the\n",
    "   disappearance of FAD landings in Viqueque after 2018?\n",
    "   WHAT WE FOUND (Ainaro): Ainaro landings were recorded as ~99% 'Reef'\n",
    "   in 2019, partially mixed in 2020 (73% Reef, 24% Beach), then 100% 'Deep'\n",
    "   from 2021 onwards with no Reef recorded at all. The switch is immediate\n",
    "   and total — not a gradual shift — and coincides with declining landing\n",
    "   counts (136 in 2019, 93 in 2021, 23 in 2023, absent from 2024). This\n",
    "   pattern is consistent with an enumerator change, not a behavioural shift.\n",
    "   WHAT WE FOUND (Viqueque FAD): 'FAD' accounted for 62.5% of Viqueque\n",
    "   landings in 2018 (180 out of 288 landings), then dropped to 1.1% in 2019\n",
    "   and near-zero in all subsequent years. Viqueque 2018 is already anomalous\n",
    "   in Phase 1 (gear: all hand line, zero long line). FAD-aggregated catch\n",
    "   inflates pelagic species (tuna, large jacks) relative to all later years.\n",
    "   FIGURE: PESKAS_3d_habitat_over_time.png\n",
    "   QUESTION (Ainaro): Was there an enumerator change in Ainaro between 2020\n",
    "   and 2021? If so, do the two enumerators have different interpretations of\n",
    "   'Reef' vs 'Deep'? The 2019-2020 Reef records and the 2021+ Deep records\n",
    "   may describe the same fishing grounds recorded with different labels.\n",
    "   QUESTION (Viqueque FAD): Was a FAD deployed near Viqueque in 2018 and\n",
    "   then removed or lost? Or did the recording protocol change so that FAD\n",
    "   landings were reclassified as 'Deep' from 2019 onwards? If the FAD was\n",
    "   genuinely active in 2018 and not after, the 2018 catch composition for\n",
    "   Viqueque is not comparable to later years.\n",
    "   WHY IT MATTERS: If Ainaro's Reef and Deep records describe the same\n",
    "   fishing grounds under different labels, splitting analyses by habitat\n",
    "   will produce spurious temporal trends. For Viqueque, using 2018 as a\n",
    "   baseline year for any catch composition or CPUE analysis will over-\n",
    "   represent pelagic species relative to the non-FAD fishery.\n\n")

cat("==============================\n")
