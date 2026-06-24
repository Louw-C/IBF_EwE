# PESKAS_2_Gear_Taxa.R
# Phase 2 — Gear × taxon catch frequency, south coast Timor-Leste
#
# Examines which taxa are caught by each gear and how catch profiles vary
# across municipalities. Municipality comparison is an enumerator-level check:
# if a gear in one municipality catches the same taxa as a different gear
# elsewhere, that points to misclassification by individual enumerators.
#
# IMPORTANT: All metrics are catch FREQUENCIES (landing presence counts).
# This script does not assess catch sizes or total weight.
#
# Input:  Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv  (READ ONLY)
#         Data/raw/Fisheries/Peskas groups_From Lore.csv          (READ ONLY)
# Output: Figures/PESKAS_2a_gear_taxon_overall.png
#         Figures/PESKAS_2b_gear_taxon_by_municipality.png
# -----------------------------------------------------------------------


# ---- 1. Packages ----
library(tidyverse)
library(RColorBrewer)
library(patchwork)


# ---- 2. Load data ----
# - cpue: one row per taxon slot per landing (including zeros)
# - lookup: maps inter-agency_code to full English names; join key = inter-agency_code

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


# ---- 3. Filter and build landing-level catch base ----
# Key structure confirmed in Script 1 sanity checks:
# - Each landing_id has exactly one gear and one habitat
# - 1,503 landings have the same taxon 2-3× with different catch values
#   (split entries): sum(catch) per landing × taxon resolves this
# - 21 landings have n_fishers = 0 but real catch: retained here because
#   this script uses catch frequencies, not CPUE

sc_munis <- c("Covalima", "Ainaro", "Manufahi", "Viqueque")

sc <- cpue |>
  filter(municipality %in% sc_munis) |>
  mutate(year = as.integer(format(as.Date(landing_date), "%Y")))

# One row per landing × taxon; zeros excluded; split entries summed
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
# Expected: 11,115 (12,512 total − 1,397 zero-catch landings)
cat("Unique taxa caught:", n_distinct(catch_base$catch_taxon), "\n")
# Expected: 44

# Remove gears with fewer than 20 landing events (all landings included, catch = 0
# and catch > 0) — too sparse to show general catch patterns and may reflect
# ambiguous or one-off recording.
# This filter is applied to ALL analyses in this script. Figures show only the
# retained dataset (same filtered sc and catch_base used throughout).
gear_counts_all <- sc |> distinct(landing_id, gear) |> count(gear, name = "n_landings")
rare_gears      <- gear_counts_all |> filter(n_landings < 20) |> pull(gear)
if (length(rare_gears) > 0) {
  n_total     <- n_distinct(sc$landing_id)
  muni_totals <- sc |> distinct(landing_id, municipality) |> count(municipality, name = "n_muni_total")
  removed     <- sc |> filter(gear %in% rare_gears) |> distinct(landing_id, municipality)
  n_removed   <- n_distinct(removed$landing_id)

  cat("\nGears removed (< 20 landing events):\n")
  gear_counts_all |>
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

  sc         <- sc         |> filter(!gear %in% rare_gears)
  catch_base <- catch_base |> filter(!gear %in% rare_gears)
  cat("South coast landings retained:", n_distinct(sc$landing_id), "\n\n")
}

# Denominators for percentages — from sc (all landings, including zero-catch trips)
n_gear_total <- sc |>
  distinct(landing_id, gear) |>
  count(gear, name = "n_gear_total")

n_gear_muni_total <- sc |>
  distinct(landing_id, gear, municipality) |>
  count(gear, municipality, name = "n_gear_muni_total")

# Taxon order for figures: most frequently caught taxon first (descending)
taxon_order <- catch_base |>
  count(catch_name_en, sort = TRUE) |>
  pull(catch_name_en)

main_gears  <- c("long line", "gill net", "hand line")
minor_gears <- setdiff(unique(sc$gear), main_gears)


# ---- 4. Step 2a: Gear × taxon catch frequency — south coast overall ----
# n_landings = unique trips where this taxon was caught by this gear
# pct_of_gear = % of all trips using this gear that caught this taxon
# Note: frequencies only — how often a taxon appears, not how much was caught

gear_taxon_overall <- catch_base |>
  filter(gear %in% main_gears) |>
  count(gear, catch_name_en, name = "n_landings") |>
  left_join(n_gear_total, by = "gear") |>
  mutate(pct_of_gear = round(n_landings / n_gear_total * 100, 1)) |>
  arrange(gear, desc(n_landings))

cat("\n=== 2a: Catch frequency by gear × taxon (south coast overall) ===\n")
cat("Note: catch frequencies only — not how much was caught, only how often.\n\n")

for (g in main_gears) {
  cat("---", toupper(g), "(", n_gear_total$n_gear_total[n_gear_total$gear == g],
      "total landings ) ---\n")
  gear_taxon_overall |>
    filter(gear == g) |>
    select(catch_name_en, n_landings, pct_of_gear) |>
    print(n = 50)
  cat("\n")
}

cat("--- MINOR GEARS (too few landings for heatmap) ---\n")
catch_base |>
  filter(gear %in% minor_gears) |>
  count(gear, catch_name_en, name = "n_landings") |>
  left_join(n_gear_total, by = "gear") |>
  mutate(pct_of_gear = round(n_landings / n_gear_total * 100, 1)) |>
  arrange(gear, desc(n_landings)) |>
  select(gear, catch_name_en, n_landings, pct_of_gear) |>
  print(n = 60)


# ---- 5. Step 2a figure: Overall gear × taxon heatmap ----
# Three separate panels joined with patchwork — one per main gear.
# Gear name and total landing count appear above each column.
# Each gear has its own colour gradient (green / blue / orange) so columns
# are visually distinct. Legend removed — shading encodes the percentage;
# landing counts are shown as numbers inside cells.
# Taxon labels shown on the left panel only; rows align across all three.

overall_grid <- expand_grid(gear = main_gears, catch_name_en = taxon_order) |>
  left_join(
    gear_taxon_overall |> select(gear, catch_name_en, n_landings, pct_of_gear),
    by = c("gear", "catch_name_en")
  ) |>
  mutate(
    n_landings = replace_na(n_landings, 0L),
    pct        = replace_na(pct_of_gear, 0),
    label      = case_when(
      n_landings == 0 ~ "",
      n_landings <  5 ~ paste0("<5 / ", pct, "%"),
      TRUE            ~ paste0(n_landings, " / ", pct, "%")
    ),
    text_col = ifelse(pct > 40, "white", "grey20")
  )

gear_palettes <- list(
  "long line" = c("#f7fcf5", "#1b5e20"),   # green
  "gill net"  = c("#e3f2fd", "#0d47a1"),   # blue
  "hand line" = c("#fff8e1", "#bf360c")    # orange
)

make_gear_panel <- function(g, show_y = TRUE) {
  n_total <- n_gear_total$n_gear_total[n_gear_total$gear == g]
  overall_grid |>
    filter(gear == g) |>
    ggplot(aes(x = gear,
               y = factor(catch_name_en, levels = rev(taxon_order)),
               fill = pct)) +
    geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = label, colour = text_col), size = 2.0, fontface = "bold") +
    scale_fill_gradient(low  = gear_palettes[[g]][1],
                        high = gear_palettes[[g]][2],
                        limits = c(0, 100)) +
    scale_colour_identity() +
    scale_x_discrete(
      position = "top",
      labels   = \(x) paste0(str_to_title(x), "\nn = ", format(n_total, big.mark = ","))
    ) +
    labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid      = element_blank(),
      axis.text.x     = element_text(size = 9, face = "bold"),
      axis.text.y     = if (show_y) element_text(size = 8) else element_blank(),
      legend.position = "none"
    )
}

p_ll <- make_gear_panel("long line", show_y = TRUE)
p_gn <- make_gear_panel("gill net",  show_y = FALSE)
p_hl <- make_gear_panel("hand line", show_y = FALSE)

p2a <- p_ll + p_gn + p_hl +
  plot_layout(ncol = 3, widths = c(2.5, 1, 1)) +
  plot_annotation(
    title    = "Step 2a: Taxon catch frequency by gear — south coast overall",
    subtitle = "% of landings where each taxon was caught. Numbers = landing counts. All values are catch frequencies, not catch sizes.",
    theme    = theme(
      plot.title    = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 9, colour = "grey40")
    )
  )

p2a 

ggsave("Figures/PESKAS_2a_gear_taxon_overall.png",
       p2a, width = 10, height = 12, dpi = 300)
cat("Saved: Figures/PESKAS_2a_gear_taxon_overall.png\n")


# ---- 6. Step 2b: Gear × taxon × municipality — enumerator check ----
# Faceted by municipality (2×2); x = gear; y = taxon (same order as 2a).
# Gear colours match Figure 2a (green / blue / orange) using pre-computed hex
# fills — scale_fill_identity() replaces the single-gradient scale.
# Grey tiles = gear not used in that municipality.
# Key diagnostic: if hand line in Manufahi catches the same demersal taxa as
# long line in Covalima/Viqueque, that signals enumerator misclassification.
# All values are catch frequencies, not catch sizes.

gear_taxon_muni <- catch_base |>
  filter(gear %in% main_gears) |>
  count(gear, municipality, catch_name_en, name = "n_landings") |>
  left_join(n_gear_muni_total, by = c("gear", "municipality")) |>
  mutate(pct = round(n_landings / n_gear_muni_total * 100, 1))

# Complete grid: all gear × municipality × taxon combinations
# fill_pct = NA  → gear not used in municipality (grey)
# fill_pct = 0   → gear used but taxon not caught (near-white of that gear's gradient)
muni_grid <- expand_grid(
  gear          = main_gears,
  municipality  = sc_munis,
  catch_name_en = taxon_order
) |>
  left_join(n_gear_muni_total, by = c("gear", "municipality")) |>
  left_join(
    gear_taxon_muni |> select(gear, municipality, catch_name_en, n_landings, pct),
    by = c("gear", "municipality", "catch_name_en")
  ) |>
  mutate(
    n_landings = replace_na(n_landings, 0L),
    fill_pct   = ifelse(is.na(n_gear_muni_total), NA_real_, replace_na(pct, 0)),
    label      = case_when(
      is.na(n_gear_muni_total) ~ "",
      n_landings == 0          ~ "",
      n_landings <  5          ~ paste0("<5 / ", fill_pct, "%"),
      TRUE                     ~ paste0(n_landings, " / ", fill_pct, "%")
    ),
    text_col = ifelse(!is.na(fill_pct) & fill_pct > 40, "white", "grey20")
  ) |>
  # Interpolate hex color per row: gear gradient scaled by fill_pct
  rowwise() |>
  mutate(fill_color = if (is.na(fill_pct)) {
    "grey80"
  } else {
    low_rgb  <- col2rgb(gear_palettes[[gear]][1])
    high_rgb <- col2rgb(gear_palettes[[gear]][2])
    mixed    <- low_rgb + (fill_pct / 100) * (high_rgb - low_rgb)
    rgb(mixed[1], mixed[2], mixed[3], maxColorValue = 255)
  }) |>
  ungroup()

p2b <- ggplot(muni_grid,
              aes(x = factor(gear, levels = main_gears),
                  y = factor(catch_name_en, levels = rev(taxon_order)),
                  fill = fill_color)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  geom_text(aes(label = label, colour = text_col), size = 1.8, fontface = "bold") +
  facet_wrap(~municipality, ncol = 2) +
  scale_fill_identity() +
  scale_colour_identity() +
  scale_x_discrete(labels = str_to_title) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid      = element_blank(),
    axis.text.x     = element_text(angle = 30, hjust = 1, size = 8, face = "bold"),
    axis.text.y     = element_text(size = 8),
    strip.text      = element_text(face = "bold", size = 10),
    legend.position = "none"
  )

# Gear colour legend: right-aligned above the main figure.
# Spacer takes the left 2/3; legend sits in the right 1/3.
# Small tiles (0.3 × 0.3) keep the legend strip compact.

leg_df <- tibble(
  label = str_to_title(main_gears),
  color = sapply(main_gears, \(g) gear_palettes[[g]][2]),
  x     = 1:3
)

p_leg <- ggplot(leg_df, aes(x = x, y = 1)) +
  geom_tile(aes(fill = color), width = 0.3, height = 0.3,
            colour = "white", linewidth = 0.3) +
  geom_text(aes(label = label, x = x + 0.22),
            hjust = 0, size = 2.8, fontface = "bold") +
  scale_fill_identity() +
  xlim(0.7, 4.5) +
  ylim(0.6, 1.4) +
  theme_void() +
  theme(plot.margin = margin(2, 4, 2, 0))

top_row <- plot_spacer() + p_leg + plot_layout(widths = c(2, 1))

p2b_out <- top_row / p2b +
  plot_layout(heights = c(1, 22)) +
  plot_annotation(
    title    = "Step 2b: Taxon catch frequency by municipality and gear",
    subtitle = paste(
      "% of landings in each gear × municipality that caught each taxon. Grey = gear not used in that municipality.",
      "Numbers = landing counts; '<5' = low confidence. All values are catch frequencies, not catch sizes.",
      sep = "\n"
    ),
    theme = theme(
      plot.title    = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 9, colour = "grey40")
    )
  )

p2b_out

ggsave("Figures/PESKAS_2b_gear_taxon_by_municipality.png",
       p2b_out, width = 11, height = 17, dpi = 300)
cat("Saved: Figures/PESKAS_2b_gear_taxon_by_municipality.png\n")


# ---- 7. Step 2c: Ecological plausibility flags ----
# Flags gear-taxon combinations that are ecologically implausible given how
# each gear works. Priority: Mackerel scad and Sardines/pilchards under long line
# and hand line — both are planktivores or filter feeders that cannot take a
# baited hook at volume. The most likely explanation is sabiki rigs (multi-hook
# feather jigs) being recorded under the wrong gear type.

cat("\n=== 2c: Ecological plausibility flags ===\n")

priority_flags <- tibble(
  gear        = c("long line", "long line", "hand line", "hand line",
                  "long line", "long line"),
  catch_name_en = c("Mackerel scad", "Sardines/pilchards",
                    "Mackerel scad", "Sardines/pilchards",
                    "Chub", "Sicklefish"),
  reason      = c(
    "Planktivore — cannot take baited hook at this volume; likely sabiki rig",
    "Filter feeder — baited hook catch implausible; likely sabiki rig",
    "Sabiki rigs routinely recorded as hand line; same issue as long line",
    "Same as above",
    "Reef-associated species; deep long line catch suspect",
    "Nearshore inshore species; deep long line unusual"
  )
)

cat("Priority implausible combinations:\n")
print(priority_flags, width = 120)

cat("\nLong line — frequency of flagged taxa:\n")
gear_taxon_overall |>
  filter(gear == "long line",
         catch_name_en %in% c("Mackerel scad", "Sardines/pilchards",
                               "Chub", "Sicklefish")) |>
  select(catch_name_en, n_landings, pct_of_gear) |>
  print()

cat("\nHand line — frequency of flagged taxa:\n")
gear_taxon_overall |>
  filter(gear == "hand line",
         catch_name_en %in% c("Mackerel scad", "Sardines/pilchards")) |>
  select(catch_name_en, n_landings, pct_of_gear) |>
  print()

cat("\n=== PHASE 2 TEAM QUESTIONS ===\n")
cat("Q1. Can you provide a clear operational description of each gear type recorded\n",
    "   in PESKAS? Specifically: hook count, line configuration, whether attended or\n",
    "   unattended, typical depth fished, and target species. This is needed to assess\n",
    "   whether gear labels in the data reflect meaningfully distinct fishing methods.\n\n")
cat("Q2. Does the PESKAS recording protocol treat sabiki rigs (multi-hook feather\n",
    "   jigs) as 'hand line'? Mackerel scad and Sardines/pilchards appear in 48% and\n",
    "   21% of hand line landings respectively — both are planktivores that cannot\n",
    "   take a baited hook, pointing to sabiki gear being recorded as hand line.\n\n")
cat("Q3. For landings where long line is the recorded gear AND Mackerel scad or\n",
    "   Sardines/pilchards dominate the catch: is this the same trip using a sabiki\n",
    "   rig alongside the long line set, or a separate trip recorded with the wrong\n",
    "   gear? These taxa appear in 30% and 24% of long line landings — understanding\n",
    "   the field situation is essential before interpreting catch composition.\n\n")
cat("Q4. In Manufahi, hand line accounts for 83% of landings and no long line is\n",
    "   recorded across any year. Do Manufahi fishers use set lines at all? If so,\n",
    "   what hook counts do they use, and how do enumerators decide whether to record\n",
    "   a trip as hand line vs long line? Data show only 11.5% of Manufahi hand line\n",
    "   trips catch demersal or large pelagic species (vs 41-74% for long line\n",
    "   elsewhere), suggesting genuine hand line behaviour rather than misclassification\n",
    "   — but field confirmation is needed.\n")
cat("==============================\n")
