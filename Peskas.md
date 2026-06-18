# PESKAS Data Investigation — South Coast Timor-Leste

Working plan for data exploration, quality checking, and metier identification using PESKAS fisheries monitoring data (2018–March 2025). All analysis is in support of the IBF_EwE model fleet structure and functional group development.

---

## Data files

All raw files in `Data/raw/Fisheries/` — never modify.

| File | Rows | Description |
|---|---|---|
| `PESKAS_timor_cpue_2018_mar2025.csv` | 221,258 | **Primary analysis file.** Landing-level records: municipality, landing site, date, gear, habitat, catch by taxon, CPUE. Long format — one row per taxon slot per landing, including zero catches. 12,512 unique south coast landing events; 51 taxon codes. |
| `PESKAS_timor_catch_2018_mar2025.csv` | 12,006 | Monthly aggregated catch by municipality and taxon. 13 taxon codes only. Use for trend reference and cross-checking only — too coarse for metier work. |
| `PESKAS_timor_length_2018_mar2025.csv` | 102,806 | Length frequency data by landing, taxon, and municipality. 17,829 south coast rows. Use to cross-check taxon composition and flag biologically implausible lengths. |
| `PESKAS_timor_boats_2021:22.csv` | — | Boat registration counts by municipality (2016 and 2021/22). Context for effort scaling. |
| `Peskas groups_From Lore.csv` | 59 rows | **Taxon lookup table.** Maps interagency codes to English names, Tetum names, family, and ISSCAAP codes. 59 groups total; 51 appear in the CPUE file. |

**South coast municipalities:** Covalima, Ainaro, Manufahi, Viqueque. All analyses filter to these four.

**Always use full taxon names** (e.g. "Mackerel scad", "Sardines/pilchards") — never raw codes (SDX, CLP). Join the lookup table at the start of every script.

---

## Script

**`PESKAS_Data_Investigation.R`** — single script with numbered sections. Inline comments explain what each section does and what the output means. This is a documented analytical record, not just computation.

Output figures saved to `Figures/`. Prefix all figure files `PESKAS_` (e.g. `PESKAS_sampling_effort.png`).

---

## Phase 1 — Sampling effort

**Goal:** Understand who is in the data, how consistently, and where confidence is low before any catch or composition analysis.

### 1a. Unique landing events by municipality and year

Count unique landing IDs (not rows) per municipality × year. Flag cells with fewer than 20 unique landings as low confidence.

**Known issues to document and confirm:**

| Municipality | Issue |
|---|---|
| Ainaro | Zero landings 2018; declines from 136 (2019) to 23 (2023); absent from 2024–2025 |
| Manufahi | Zero landings in 2022 — complete data gap |
| Viqueque | 288 landings in 2018 (thin); rises to 1,033 in 2019 — early ramp-up period |
| Covalima | 2,024 landings (2021) → 272 (2023) → 646 (2024) — large unexplained swings |

Output: summary table printed to console; heatmap of landing counts by municipality × year with low-confidence cells highlighted.

**Question for PESKAS team:** For Manufahi 2022 and the Ainaro drop-off from 2023 — were these genuine monitoring gaps (staff, funding, access), or were data collected but lost or excluded?

### 1b. Gear coverage by municipality and year

Count unique landing events per gear type × municipality × year. Flag gear × municipality combinations with fewer than 20 landings.

Known dominant pattern: long line accounts for the large majority of south coast landing records. Confirm whether this reflects true fishing effort composition or a sampling bias toward certain landing sites or enumerators.

Output: table of landing counts by gear × municipality × year.

### 1c. Rows per landing distribution

The CPUE file is long format — each landing generates multiple rows (one per taxon slot, including zeroes). Most landings have ~10–35 rows. Flag any landing with an unusually high row count (>50), as this may indicate a recording protocol change.

Known flag: Covalima 2024 — 646 unique landings generate 21,759 rows (~34 rows/landing vs typical ~10). Investigate whether the taxon slot set expanded in 2024.

Output: distribution of rows per landing ID; flag landings >50 rows; note any year/municipality patterns in the distribution.

---

## Phase 2 — Gear × taxa

**Goal:** Identify ecologically implausible gear–taxon combinations that indicate misclassified gear or mislabelled catch. These flags must be resolved before defining metiers.

### 2a. Gear × taxon catch record counts

For each gear type, count the number of non-zero catch records per taxon. Use full taxon names throughout.

Known dominant gears (non-zero south coast catch records):

| Gear | Records |
|---|---|
| Long line | 14,218 |
| Gill net | 2,343 |
| Hand line | 1,224 |
| Beach seine | 37 |
| Other (manual collection, cast net, seine net, spear gun) | <30 each |

Output: table of record counts by gear × taxon (full names), sorted by gear then descending count.

### 2b. Ecological plausibility assessment

For each gear × taxon combination, assess whether the catch is ecologically plausible given how the gear works. Build an internal reference table of expected and unlikely combinations.

**Reference table — gear mechanics and expected catch:**

| Gear | Ecologically expected catch | Ecologically unlikely catch |
|---|---|---|
| Long line (demersal, baited hooks) | Snapper/seaperch, Grouper, Emperor, Jobfish, Sharks, Stingrays, Jacks/Trevally | Sardines/pilchards, Mackerel scad, Fusilier, Parrotfish, Surgeonfish, Garfish |
| Gill net (surface to mid-water) | Garfish, Sardines/pilchards, Wolf herring, Flying fish, Jacks/Trevally, Tuna/Bonito, Sharks | Few absolute exclusions — check proportions |
| Hand line (baited single hook) | Snapper/seaperch, Grouper, Emperor, Barracuda, Jacks/Trevally | Sardines/pilchards, Mackerel scad, Fusilier |
| Beach seine (nearshore sweep) | Sardines/pilchards, Garfish, small nearshore pelagics | Reef fish, large predators, deep demersal |
| Manual collection / gleaning | Octopus, Crab, Cockles, Sea cucumber, Lobster | Pelagic or demersal fish |

**Priority flags from initial data review:**

| Taxon | Gear | Records | Assessment |
|---|---|---|---|
| Mackerel scad | Long line | 2,853 | Planktivore — cannot take baited hooks at this volume. Almost certainly sabiki rig or cast net, misrecorded as long line. |
| Sardines/pilchards | Long line | 2,227 | Same as above — filter feeder, baited hook catch implausible. |
| Mackerel scad | Hand line | 670 | Confirms sabiki hypothesis — sabiki rigs are routinely recorded as hand line. |
| Sardines/pilchards | Hand line | 301 | Same. |
| Chub | Long line | 98 | Reef-associated herbivore; deep long line catch is suspect. |
| Sicklefish | Long line | 68 | Nearshore inshore species; deep long line unusual. |

Output: heatmap of record counts by gear × taxon (full names); implausible cells highlighted in a distinct colour. Calculate and print the percentage of long line landings that contain Mackerel scad or Sardines/pilchards.

**Question for PESKAS team:** Does the PESKAS field recording protocol treat sabiki rigs and multi-hook feather jigs as "hand line"? López-Angarita et al. (2020) document hook sizes #4–18 recorded as hand line. If this applies to south coast enumerators, it partially explains the small pelagic catch under hand line — but not the same groups under long line.

**Question for PESKAS team:** For landings where long line is the recorded gear and Mackerel scad or Sardines/pilchards are the dominant catch — is this the same trip using a different method (sabiki from the same boat), or is it a gear recording error?

### 2c. Taxon coverage: CPUE file vs aggregated catch file vs lookup

The aggregated catch file contains 13 taxon codes. The CPUE landing-level file contains 51 codes. The lookup table has 59 groups. Map these against each other.

- Which of the 51 CPUE codes are collapsed into which of the 13 aggregated codes?
- Which of the 59 lookup groups are absent from the south coast CPUE entirely?
- MZZ (Other/Unknown) appears in the aggregated catch file but has **zero non-zero catch records in the south coast CPUE** — flag and investigate. Either "Other" catches are absorbed into other codes in landing-level recording, or MZZ was only needed at the aggregation stage.

Output: printed mapping table — PESKAS code, full English name, family, present in CPUE (yes/no), present in aggregated catch (yes/no). Flag the five lookup codes absent from CPUE entirely: Other/Unknown (MZZ), Cuttlefish (IAX), Ponyfish (LGE), Tripodfish (PUX), Seaweed (SWX).

---

## Phase 3 — Habitat × gear × taxa

**Goal:** Assess whether the habitat field is ecologically interpretable, or whether it records departure point rather than fishing ground. This matters for linking catch groups to EwE functional group habitat assignments.

### 3a. Habitat coverage by municipality

Count non-zero catch records by habitat × municipality. Known pattern: "Deep" accounts for ~88% of south coast non-zero catch records, which is ecologically inconsistent with a largely non-motorised nearshore fishery (López-Angarita et al. 2020 notes 71% of boats are non-motorised and most fish within 5 km of shore).

Output: table of record counts by habitat × municipality.

**Question for PESKAS team:** Does "Deep" refer to water depth (the boat fished in deeper water), distance from shore, or substrate type (rocky/sandy bottom below reef)? If "Deep" means anything other than open-water offshore fishing, the habitat labels are not comparable to standard habitat classifications.

### 3b. Habitat × taxon catch composition

For each habitat type, calculate the proportion of non-zero catch records contributed by each taxon (full names). Flag habitat × taxon combinations that are ecologically implausible.

**Priority flags:**
- Sardines/pilchards or Mackerel scad recorded under "Reef" habitat — are these fish being caught on the reef or is the boat recording its launch site?
- Snapper/seaperch or Grouper recorded under "Beach" habitat — benthic reef fish in a beach-seine or nearshore context
- Tuna/Bonito under "Mangrove" or "Seagrass" — open-water pelagics in nearshore habitats

Output: heatmap of proportion of catch records by habitat × taxon (full names); flag ecologically implausible cells.

### 3c. Gear × habitat combinations

Count landing events per gear × habitat combination. Assess whether gear-habitat pairs make operational sense (e.g. beach seine at Deep is implausible; long line at Beach is unusual).

Output: table of landing counts by gear × habitat; flag low-count or implausible combinations.

### 3d. Structured question list for PESKAS team

At the end of Phase 3, compile all flagged questions into a single structured list. One entry per question, formatted as:

- **What we found:** brief description of the pattern
- **The figure:** which output to show
- **The question:** what we need to know to interpret it correctly
- **Why it matters:** how the answer affects the metier classification or EwE model

This list is the primary deliverable from Phases 1–3 — it goes into a meeting with Lore (Lorenzo Longobardi, PESKAS team).

---

## Phase 4 — Spatial and temporal patterns (deferred)

Proceed only after Phase 1–3 questions have been resolved with the PESKAS team, so that anomalies are correctly interpreted rather than treated as real ecological signals.

### 4a. Municipality-level catch composition over time

For each municipality, plot total non-zero catch (kg) by taxon group (full names) per year. Look for sudden compositional shifts inconsistent with ecology — these likely reflect changes in sampling methodology or landing site coverage rather than genuine fishery change.

Known flag: Covalima shows a large unexplained swing (2,024 landings in 2021 → 272 in 2023 → 646 in 2024).

### 4b. Landing site coverage

Map which landing sites are monitored and in which years. A change in the set of monitored sites will produce apparent catch changes that are sampling artefacts.

### 4c. Cross-check against aggregated catch file

For the 13 taxons that appear in both the CPUE and aggregated catch files, compare the landing-level proportional composition against the aggregated estimates. Large divergences indicate either the aggregation method or the raising factors are distorting the picture.

---

## Metier hypotheses (preliminary — to be tested in Phase 4+)

Based on data structure only. Do not commit to these before Phase 1–3 quality checks and PESKAS team discussion.

| Candidate metier | Gear | Primary taxa | Habitat signal |
|---|---|---|---|
| M1: Deep long line — demersal predators | Long line | Snapper/seaperch, Grouper, Emperor, Jobfish, Sharks | Deep |
| M2: Deep long line — large pelagics | Long line | Jacks/Trevally, Short-bodied mackerel, Tuna/Bonito | Deep |
| M3: Gill net — surface/nearshore pelagics | Gill net | Garfish, Sardines/pilchards, Wolf herring, Flying fish | Beach/Reef |
| M4: Gill net — mixed | Gill net | Jacks/Trevally, Sardines/pilchards, Sharks | Reef |
| M5: Sabiki/jigging — small pelagics | Recorded as "long line" or "hand line" | Mackerel scad, Sardines/pilchards | Unknown |
| M6: Beach seine — nearshore | Beach seine | Garfish | Beach |

The central unresolved question: are the Mackerel scad and Sardines/pilchards records under long line (2,853 and 2,227 records) from separate sabiki trips, or the same trip as the demersal long line set? If separate, M1 and M5 are distinct metiers. If same trip, long line catch is mixed and metier structure will rely on dominant target species rather than gear alone.

---

## R coding conventions for this analysis

Follow the global R rules from `~/.claude/CLAUDE.md`:

- Number all sections: `# 1. Load data`, `# 2. Filter to south coast`, etc.
- Before each section, a short comment block: what is being done and why (bullet style)
- For any check with a known expected answer, include it inline: `# Expected: 12,512 unique landing IDs`
- Print all key results explicitly — nothing silent
- Use full taxon names throughout — join the lookup table at the start, never use raw codes in outputs
- Minimum code — no unnecessary intermediate objects
