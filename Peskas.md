# PESKAS Data Investigation — South Coast Timor-Leste

Working plan for data exploration, quality checking, and metier identification using PESKAS fisheries monitoring data (2018–March 2025). All analysis is in support of the IBF_EwE model fleet structure and functional group development.

## Status (last updated 2026-06-23)

| Phase | Script | Status |
|---|---|---|
| Phase 1 — Sampling effort | `PESKAS_1_Sampling_Effort.R` | COMPLETE |
| Phase 2 — Gear × taxa | `PESKAS_2_Gear_Taxa.R` | COMPLETE |
| Phase 2c — Taxon coverage cross-check | (Section 7 of Script 2) | COMPLETE |
| Phase 3 — Habitat × gear × taxa | `PESKAS_3_Habitat_Gear_Taxa.R` | COMPLETE |
| **NEXT: Draft report for PESKAS team** | — | **NEXT SESSION (2026-06-24)** |
| Phase 4 — Spatial/temporal | — | Deferred — resolve team questions first |
| Metier formalisation | — | Deferred — after Phase 4 and team meeting |

---

## Data files

All raw files in `Data/raw/Fisheries/` — never modify.

| File | Rows | Description |
|---|---|---|
| `PESKAS_timor_cpue_2018_mar2025.csv` | 221,258 | **Primary analysis file.** Landing-level records: municipality, landing site, date, gear, habitat, catch by taxon, CPUE. Long format — one row per taxon slot per landing, including zero catches. 12,512 unique south coast landing events; 51 taxon codes. |
| `PESKAS_timor_catch_2018_mar2025.csv` | 12,006 | Monthly aggregated catch by municipality and taxon. 13 taxon codes only. Use for trend reference and cross-checking only — too coarse for metier work. |
| `PESKAS_timor_length_2018_mar2025.csv` | 102,806 | Length frequency data by landing, taxon, and municipality. 17,829 south coast rows. Use to cross-check taxon composition and flag biologically implausible lengths. |
| `PESKAS_timor_boats_2021:22.csv` | — | Boat registration counts by municipality (2016 and 2021/22). Context for effort scaling. |
| `Peskas groups_From Lore.csv` | 59 rows | **Taxon lookup table.** Maps interagency codes to English names, Tetum names, family, and ISSCAAP codes. 59 groups total; 51 appear in the CPUE file. Join at the start of every script. |

**South coast municipalities:** Covalima, Ainaro, Manufahi, Viqueque. All analyses filter to these four.

**Always use full taxon names** (e.g. "Mackerel scad", "Sardines/pilchards") — never raw codes (SDX, CLP). Join the lookup table at the start of every script.

---

## Scripts

Three separate scripts, one per phase. All in `IBF_EwE/Code/`. All figures saved to `IBF_EwE/Figures/` with `PESKAS_` prefix.

Each script follows the same structure:
- Numbered sections with short bullet-style comment blocks
- Known expected values stated inline (e.g. `# Expected: 12,512`)
- All key results printed explicitly — nothing silent
- Full taxon names throughout — raw codes never appear in output
- Zero-catch rows excluded; split entries (same taxon 2–3× per landing) summed before analysis

---

## Critical data structure facts
*(Confirmed in Script 1, Sections 9–14 — apply to all scripts)*

- **cpue** = `tot_catch / (n_fishers × trip_length)` — landing-level total; same value on all rows for a landing
- **cpue_fish_group** = `catch / (n_fishers × trip_length)` — taxon-specific rate; use this for per-taxon effort analysis
- Each landing has **exactly one gear** and **exactly one habitat**
- **n_fishers = 0**: 21 landing events (0.17% of south coast), mostly Covalima 2019–2020. Real catch present → Inf CPUE. Exclude from CPUE analysis; catch values usable.
- **Split entries**: 1,503 landings (12%) have the same taxon appear 2–3× with different catch values. These are not errors — `tot_catch` is correct. Always `sum(catch)` per taxon per landing; never use `first()` or `slice(1)`. Most affected: Jacks/Trevally (803 pairs), Snapper/seaperch (420). Heavy in Viqueque all years and Ainaro 2019–2020.
- **Taxon codes**: all 51 codes in the CPUE file match `interagency_code` in the lookup table (confirmed). The code `0` = no-catch rows; filtered out by `catch > 0`.

---

## Phase 1 — Sampling effort
**Script:** `PESKAS_1_Sampling_Effort.R` | **Status:** COMPLETE

**Goal:** Understand who is in the data, how consistently, and where confidence is low before any catch or composition analysis.

### Figures produced
- `PESKAS_1a_landing_events_monthly_heatmap.png` — unique landings by municipality × year × month; grey = no monitoring
- `PESKAS_1b_gear_coverage.png` — gear composition by municipality × year (stacked bar)
- `PESKAS_1c_habitat_coverage.png` — habitat composition by municipality × year (stacked bar)
- `PESKAS_1d_rows_per_landing.png` — mean rows per landing heatmap (protocol change check)

### Confirmed findings

**Coverage gaps:**
| Municipality | Issue |
|---|---|
| Ainaro | Zero landings 2018; declines from 136 (2019) to 23 (2023); absent from 2024–2025 |
| Manufahi | Zero landings in 2022 — complete monitoring gap |
| Viqueque | 288 landings in 2018 (thin); rises to 1,033 in 2019 |
| Covalima | 2,024 landings (2021) → 272 (2023) → 646 (2024) — large unexplained swings |
| Covalima 2024 | ~34 rows/landing vs typical ~5 — taxon slot expansion suspected |

**Gear flags:**
- Viqueque 2018: 248 hand line landings, 0 long line → from 2019 onward near-zero hand line, long line dominates. Almost certain reclassification event.
- Manufahi: zero long line across all years despite it being the dominant gear elsewhere. Likely enumerators record multi-hook bottom lines as hand line.
- Viqueque beach seine: very small count — may be gill net misclassified.

**Geographic gear split (important for metiers):**
- Ainaro and Manufahi: hand line and gill net only — NO long line
- Covalima and Viqueque: long line dominant

**Habitat flags (from Script 1):**
- Viqueque FAD 2018: FAD accounted for 62.5% of Viqueque landings — verify whether a FAD was deployed.
- Manufahi Reef: field knowledge suggests "Reef" is overused as a default label.
- Ainaro: Reef/Deep reclassification suspected across years (confirmed in Phase 3).

### Team questions raised
- For Manufahi 2022 and Ainaro drop-off from 2023: genuine monitoring gap or data collected but excluded?
- Does Manufahi long line genuinely not exist, or are multi-hook lines recorded as hand line?

---

## Phase 2 — Gear × taxa
**Script:** `PESKAS_2_Gear_Taxa.R` | **Status:** COMPLETE

**Goal:** Identify ecologically implausible gear–taxon combinations that indicate misclassified gear or mislabelled catch. These flags must be resolved before defining metiers.

### Figures produced
- `PESKAS_2a_gear_taxon_overall.png` — three-panel heatmap; long line (green), gill net (blue), hand line (orange); cell labels = landing count / %; denominator = all south coast landings per gear
- `PESKAS_2b_gear_taxon_by_municipality.png` — same metric faceted 2×2 by municipality; highlights where gear × taxon profiles diverge across municipalities

### Analysis structure
- **2a:** Catch frequency by gear × taxon (% of all landings for that gear where taxon was caught). Three main gears only (long line, gill net, hand line); minor gears printed to console.
- **2b:** Same metric split by municipality. Key diagnostic: if hand line in Manufahi catches the same demersal taxa as long line in Covalima/Viqueque, it signals enumerator misclassification.
- **2c:** Taxon coverage cross-check — maps the 51 CPUE codes against the 13 aggregated-file codes and the 59 lookup codes. Five lookup codes absent from south coast CPUE: Other/Unknown (MZZ), Cuttlefish (IAX), Ponyfish (LGE), Tripodfish (PUX), Seaweed (SWX).

### Confirmed ecological plausibility flags

| Taxon | Gear | Landings | Assessment |
|---|---|---|---|
| Mackerel scad | Long line | 2,853 | Planktivore — cannot take baited hook at volume. Almost certainly sabiki rig misrecorded as long line. |
| Sardines/pilchards | Long line | 2,227 | Filter feeder — same issue. |
| Mackerel scad | Hand line | 670 | Sabiki rigs routinely recorded as hand line. |
| Sardines/pilchards | Hand line | 301 | Same. |
| Chub | Long line | 98 | Reef-associated herbivore; deep long line catch suspect. |
| Sicklefish | Long line | 68 | Nearshore inshore species; deep long line unusual. |

**Central unresolved question:** Are the Mackerel scad and Sardines/pilchards records under long line from separate sabiki trips, or the same trip as the demersal long line set? If separate → M1 and M5 are distinct metiers. If same trip → metier structure must rely on dominant target species, not gear alone.

### Team questions (Section 7 of Script 2)
- Q1: Can you provide a clear operational description of each gear type — hook count, line configuration, attended/unattended, typical depth, target species?
- Q2: Does the PESKAS protocol treat sabiki rigs as "hand line"? Mackerel scad and Sardines/pilchards appear in 48% and 21% of hand line landings — both planktivores that cannot take a baited hook.
- Q3: For long line landings where Mackerel scad or Sardines/pilchards dominate: same trip with a sabiki rig alongside the long line set, or a separate trip with wrong gear recorded?
- Q4: In Manufahi, hand line accounts for 83% of landings and no long line is recorded. Do Manufahi fishers use set lines? How do enumerators decide hand line vs long line?

---

## Phase 3 — Habitat × gear × taxa
**Script:** `PESKAS_3_Habitat_Gear_Taxa.R` | **Status:** COMPLETE

**Goal:** Assess whether the habitat field is ecologically interpretable (fishing ground) or records the boat's departure point. Habitat must be meaningful before it can be used as a third metier dimension or linked to EwE functional group habitat assignments.

### Figures produced
- `PESKAS_3a_habitat_municipality.png` — habitat × municipality heatmap; % of landing events per municipality; blue gradient
- `PESKAS_3b_habitat_taxon.png` — habitat × taxon heatmap; % of landings in each habitat where taxon was caught; taxa ordered most-to-least frequent (consistent with Script 2)
- `PESKAS_3c_gear_habitat.png` — gear × habitat heatmap; % of each gear's total landings in each habitat; grey = combination not observed
- `PESKAS_3d_habitat_over_time.png` — stacked bar by year × municipality (2×2 facet); reveals Ainaro Reef→Deep reclassification and Viqueque FAD collapse

### Analysis structure

**3a — Habitat coverage by municipality:** Landing events per habitat × municipality as % within municipality. "Deep" dominates (~88% of south coast landings) across all four municipalities and all gear types — ecologically inconsistent with a largely non-motorised nearshore fishery (López-Angarita et al. 2020: 71% of boats non-motorised, most fish within 5 km of shore).

**3b — Habitat × taxon catch frequency:** % of all landings in each habitat that caught each taxon. Denominator = all sc landings per habitat (including zero-catch trips). Two sets of flags coded in the script:

*(a) Cross-habitat flags — implausible if habitat = fishing ground:*
- Sardines/pilchards and Mackerel scad under "Reef" — open-water schoolers
- Snapper/seaperch, Grouper, Emperor under "Beach" — benthic reef fish
- Tuna/Bonito under "Mangrove" or "Seagrass" — open-water pelagics

*(b) Deep-specific flags — reef-obligate or shallow species under "Deep" inconsistent with offshore water:*
- Parrotfish, Surgeonfish, Wrasse, Soldierfish, Fusilier, Moray — all reef-obligate or reef-associated
- Crab, Octopus, Shrimp — benthic intertidal/shallow
- Milkfish — estuarine/coastal

**Deep vs Reef profile comparison:** Pearson correlation of taxon frequency profiles between "Deep" and "Reef" computed in script. High correlation (>0.8) = profiles ecologically indistinguishable = labels used interchangeably. Per-taxon table printed sorted by absolute difference.

**3c — Gear × habitat combinations:** Full gear × habitat matrix. Implausible combinations flagged: beach seine at Deep, long line at Beach, manual collection at Deep, spear gun at Deep. Also tests whether habitat separates the main gears — if long line and hand line share identical habitat profiles, habitat adds no discriminating power as a metier dimension.

**3d — Habitat over time by municipality:** Stacked bar (year × municipality). Key diagnostic: stable proportions = consistent recording; abrupt shifts = enumerator or protocol change.

### Confirmed temporal anomalies

**Ainaro — Reef → Deep reclassification (2020 → 2021):**
- 2019: 98.5% Reef, 0.7% Deep
- 2020: 72.8% Reef, 23.9% Beach, 2.2% Deep (transitional)
- 2021–2023: 100% Deep, zero Reef
- Pattern is immediate and total — consistent with an enumerator change, not a real behavioural shift. The Reef records (2019–2020) and Deep records (2021+) may describe the same fishing grounds under different labels.

**Viqueque — FAD disappearance (2018 → 2019):**
- 2018: 62.5% FAD (180 landings), 20% Deep, 15% Beach
- 2019: 97.5% Deep, 1.1% FAD — FAD essentially gone
- 2020–2025: 99–100% Deep
- FAD-aggregated catch in 2018 inflates pelagic species (tuna, large jacks) relative to all later years. Combined with Viqueque 2018 gear anomaly (all hand line, zero long line from Phase 1), **2018 Viqueque should not be used as a baseline year** for any catch composition or CPUE analysis.

### Team questions (Section 11 of Script 3, Q1–Q6)
- Q1: What does "Deep" mean in PESKAS? Water depth, distance from shore, substrate type, or residual default?
- Q2: Are "Deep" and "Reef" being used interchangeably? Is there a formal protocol definition, and is it applied consistently across enumerators?
- Q3: Is "Reef" the launch site or the fishing ground? (Sardines/pilchards and Mackerel scad appear under Reef — both open-water species)
- Q4: Are demersal species under "Beach" caught inshore, or from boats that departed from a beach landing site?
- Q5: Why does manual collection (gleaning) appear under "Deep"? Default entry or genuine free-diving?
- Q6: What explains the Ainaro Reef→Deep reclassification (2020→2021) and the Viqueque FAD disappearance (2018→2019)? Enumerator change, protocol change, or real operational change?

---

## Phase 4 — Spatial and temporal patterns (deferred)

Proceed only after Phase 1–3 questions have been resolved with the PESKAS team. Running Phase 4 before resolution risks treating recording artefacts (enumerator changes, protocol shifts) as real ecological signals.

### 4a. Municipality-level catch composition over time
For each municipality, plot total non-zero catch (kg) by taxon per year. Sudden compositional shifts inconsistent with ecology likely reflect sampling methodology changes. Known flag: Covalima 2,024 landings (2021) → 272 (2023) → 646 (2024).

### 4b. Landing site coverage
Map which landing sites are monitored and in which years. A change in monitored sites produces apparent catch shifts that are pure sampling artefacts.

### 4c. Cross-check against aggregated catch file
For the 13 taxons in both files, compare landing-level proportional composition against monthly aggregated estimates. Large divergences indicate problems in the raising factors.

---

## Metier hypotheses (preliminary — do not commit before team meeting)

| Candidate metier | Gear | Primary taxa | Habitat signal |
|---|---|---|---|
| M1: Deep long line — demersal predators | Long line | Snapper/seaperch, Grouper, Emperor, Jobfish, Sharks | Deep |
| M2: Deep long line — large pelagics | Long line | Jacks/Trevally, Short-bodied mackerel, Tuna/Bonito | Deep |
| M3: Gill net — surface/nearshore pelagics | Gill net | Garfish, Sardines/pilchards, Wolf herring, Flying fish | Beach/Reef |
| M4: Gill net — mixed | Gill net | Jacks/Trevally, Sardines/pilchards, Sharks | Reef |
| M5: Sabiki/jigging — small pelagics | Recorded as "long line" or "hand line" | Mackerel scad, Sardines/pilchards | Unknown |
| M6: Beach seine — nearshore | Beach seine | Garfish | Beach (37 records — may be too sparse) |

**Habitat note:** Whether "Deep" and "Reef" can serve as discriminating dimensions for M1 vs M2 (or M3 vs M4) depends entirely on what the team meeting reveals about what those labels actually mean. If Deep and Reef are interchangeable or both record departure point, habitat cannot be used as a metier dimension and fleet structure must rely on gear × target taxon alone.

---

## Next steps

1. **Review Scripts 1–3 outputs** (figures + console output) — session 2026-06-24
2. **Draft short report for PESKAS team** — findings summary + all questions from Scripts 1–3, formatted for email ahead of requesting a meeting with Lore (Lorenzo Longobardi)
3. **PESKAS team meeting** — work through questions; resolve gear and habitat recording protocol; confirm FAD and enumerator history
4. **Phase 4** — spatial/temporal analysis, after team meeting
5. **Metier formalisation** — define M1–M6 with data-grounded gear, taxon, habitat, and seasonal parameters for EwE fleet structure

---

## R coding conventions

Follow the global R rules from `~/.claude/CLAUDE.md`:

- Number all sections: `# ---- 1. Packages ----`, `# ---- 2. Load data ----`, etc.
- Before each section, a short bullet-style comment block explaining what is being done and why
- For any check with a known expected answer, state it inline: `# Expected: 12,512 unique landing IDs`
- Print all key results explicitly — nothing silent
- Use full taxon names throughout — join the lookup table at the start of every script; never use raw codes in output
- Minimum code — no unnecessary intermediate objects
- All figures saved to `Figures/` with `PESKAS_` prefix and step number (e.g. `PESKAS_2a_gear_taxon_overall.png`)
