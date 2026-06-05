# Diet Matrix Development — South Coast EwE Model

Workflow for building the Ecopath diet matrix for the Timor-Leste south coast using a hybrid species list approach, processed through the AI-EwE-Diets pipeline (Spillias et al. 2025).

**Approach:** Three-tier species list grounded in local data, supplemented by reference models and OBIS, fed into an AI pipeline that automates diet matrix construction. The AI produces an ecologically informed first draft; expert review and refinement produces the final matrix.

**GitHub repo:** github.com/s-spillias/AI-EwE-Diets

---

## Background: Why a Hybrid Approach?

A raw OBIS polygon search for the south coast is insufficient because:

- OBIS coverage of Timor-Leste is sparse and taxonomically patchy — many commercially important fish are recorded but most invertebrates, zooplankton, and lower trophic groups are missing or underrepresented
- OBIS presence ≠ ecologically relevant — a species recorded once by a passing research vessel is not the same as a genuine food web component
- We already have a better species list for fished components: PESKAS 57+ groups, Alex's BRUV data, NOAA surveys

Instead, we build a **three-tier species list**:

| Tier | Source | What it covers |
|---|---|---|
| **Tier 1** | PESKAS, BRUV surveys, NOAA surveys, literature | Confirmed present — the fished and observed assemblage |
| **Tier 2** | Ecobase 405 (Australian NW Shelf) reference model | Ecologically necessary groups absent from catch/survey data (zooplankton, phytoplankton, benthic invertebrates) |
| **Tier 3** | OBIS broad polygon (Timor Sea / Banda Sea) | Regional supplement for species likely present but not directly observed |

All three tiers are merged into a single master species CSV, which replaces the Stage 1 output of the AI-EwE-Diets pipeline. Stages 2–5 then run as normal.

---

## Phase 0: Setup and Preparation

- [ ] **0.1** Clone `github.com/s-spillias/AI-EwE-Diets` into `IBF_EwE/Code/AI-EwE-Diets/`
- [ ] **0.2** Read the README; examine Stage 1 output CSV format exactly — column names, required fields, data types; document the exact format needed as the target for the merge script
- [ ] **0.3** Run the pipeline once on a tiny test polygon (e.g., 5 known species) to confirm Stage 1 → Stage 2 handoff works and to see a real example of the Stage 1 CSV output
- [ ] **0.4** Obtain a Claude API key (Anthropic console); add to `.Renviron` as environment variable — do not hardcode in scripts
- [ ] **0.5** Estimate API cost for ~500–800 species; confirm budget is acceptable before full run
- [ ] **0.6** Install all required R packages from the repo: `robis`, `taxize`, `dplyr`, `tidyr`, `jsonlite`, `httr`, `DuckDB`, `arrow`

---

## Phase 1: Build Tier 1 — South Coast Species Data

*The backbone. Species confirmed present in the south coast system from direct observation or monitoring.*

**Script: `Code/Diet_Matrix/Tier1_Species_Compilation.R`**

- [ ] **1.1 — PESKAS full classification (57+ groups)**
  - Input: `Data/raw/Fisheries/Peskas groups_From Lore.csv`
  - Extract all unique scientific names; note ISSCAAP codes and Tetum names for cross-referencing
  - Flag catch-category aggregations (e.g., SNA = multiple snapper species) — these need resolving to representative species or genus-level entries
  - Tag source = "PESKAS_Classification"

- [ ] **1.2 — PESKAS CPUE data (additional taxa)**
  - Input: `Data/raw/Fisheries/PESKAS_timor_cpue_2018_mar2025.csv`
  - Filter to south coast municipalities (Covalima, Ainaro, Manufahi, Viqueque)
  - Extract all unique taxon codes; map against the 57-group lookup
  - Identify any taxa in CPUE not in the classification lookup
  - Tag source = "PESKAS_CPUE"

- [ ] **1.3 — Alex's BRUV survey data**
  - Input: Alex's BRUV/survey data in `Data/raw/Biological/`
  - Extract all species recorded across the full survey — include species observed but not targeted (ecologically important even if not in PESKAS)
  - Tag source = "BRUV_Survey"

- [ ] **1.4 — NOAA surveys (2013–2014, 2016, 2018)**
  - Input: `Data/raw/Biological/` — NOAA fish biomass and benthic cover data
  - Extract all species identified in NOAA fish biomass surveys
  - Extract major benthic categories (coral cover, echinoderm presence) for functional group coverage
  - Tag source = "NOAA_Survey"

- [ ] **1.5 — Literature extraction**
  - Input: papers in `Literature/` — Yang MSc thesis, CI 2013 report, NOAA 2017 report, Lopez-Angarita et al.
  - Manually extract species or functional groups mentioned as present on the south coast not already captured above
  - Focus on: sharks and rays, sea turtles, marine mammals (dugongs, dolphins), invertebrates of economic importance (sea cucumbers, lobsters, octopus)
  - Tag source = "Literature"

- [ ] **1.6 — Compile and deduplicate Tier 1**
  - Combine all 1.1–1.5 outputs
  - Deduplicate on scientific name (check for synonyms)
  - Document resolution decisions for ambiguous aggregations (e.g., how SNA is handled)
  - Output: `Data/processed/Tier1_species_list.csv` — expected ~150–250 entries

---

## Phase 2: Build Tier 2 — Reference Model Backbone

*Ecologically necessary groups that must be in any EwE model but may not appear in catch or survey data.*

**Script: `Code/Diet_Matrix/Tier2_Reference_Model.R`** (builds on existing `Code/Ecobase.R`)

- [ ] **2.1 — Extract Ecobase 405 functional group list**
  - Input: Australian NW Shelf model (Ecobase 405) via existing `Code/Ecobase.R`
  - Pull complete functional group list with trophic levels and diet compositions
  - Categorise groups: fish vs. invertebrates vs. plankton vs. primary producers

- [ ] **2.2 — Identify coverage gaps in Tier 1**
  - Compare Tier 1 against the reference model group list
  - Identify groups present in the reference model but absent from Tier 1 — these are almost certainly in the south coast ecosystem but not directly observed
  - Focus especially on: mesozooplankton, microzooplankton, phytoplankton, macrozoobenthos, meiobenthos, benthic filter feeders, deposit feeders, detritus

- [ ] **2.3 — Assign representative taxa to Tier 2 groups**
  - For each gap group, assign a representative taxon at the lowest meaningful taxonomic level
  - Examples: "mesozooplankton" → Order Calanoida; "benthic filter feeders" → Class Bivalvia; "phytoplankton" → Class Bacillariophyceae
  - Genus or higher is fine for non-fished groups — exact species not required
  - Tag source = "Reference_Model_Ecobase405"
  - Output: `Data/processed/Tier2_species_list.csv` — expected ~20–40 entries

---

## Phase 3: Build Tier 3 — OBIS Regional Supplement

*Regional fill for species likely present but not in direct data. Used cautiously as a supplement, not a foundation.*

**Script: `Code/Diet_Matrix/Tier3_OBIS_Supplement.R`**

- [ ] **3.1 — Define the broad search polygon**
  - Draw polygon covering Timor Sea and western Banda Sea: approximately 7–12°S, 123–128°E
  - Intentionally wider than the south coast shelf to capture the regional species pool (Indonesian and Australian OBIS records have better coverage than TL-specific ones)

- [ ] **3.2 — Run OBIS checklist query**
  - Use `robis::checklist()` with the broad polygon
  - Filter: `is_marine = TRUE`; remove terrestrial and freshwater taxa
  - Apply taxonomic deduplication: retain only the most specific taxonomic level per organism (matching the paper's approach — if both *Lutjanus bohar* species-level and *Lutjanus* genus-level are returned, keep species-level only)

- [ ] **3.3 — Filter to south coast shelf relevance**
  - Remove taxa ecologically implausible for a shallow (0–200m) tropical coastal shelf:
    - Deep-sea and abyssal taxa (>500m)
    - Polar and cold-water species
    - Open-ocean epipelagic species with no shelf records (except tuna/billfish)
    - Freshwater-associated species
  - Where possible, cross-reference FishBase depth ranges to filter by 0–200m overlap

- [ ] **3.4 — Subtract Tiers 1 and 2**
  - Remove any species already present in `Tier1_species_list.csv` or `Tier2_species_list.csv`
  - Review what remains: assess whether it adds useful coverage for sharks/rays, non-commercial reef fish, non-target invertebrates, seabirds, turtles, marine mammals

- [ ] **3.5 — Expert filter**
  - Manually review the remaining OBIS species
  - Retain: species that fill genuine gaps in trophic coverage for the south coast shelf
  - Discard: rare or accidental occurrences; taxa with only 1–2 OBIS records in the region; highly specialist groups already represented by broader Tier 2 entries
  - Tag source = "OBIS_Regional"
  - Output: `Data/processed/Tier3_species_list.csv` — expected ~100–300 entries after filtering

---

## Phase 4: Merge, Deduplicate, and Taxonomic Standardisation

*Produce the single master species CSV in Stage 1 format.*

**Script: `Code/Diet_Matrix/Species_List_Merge.R`**

- [ ] **4.1 — Combine all three tiers**
  - Merge `Tier1_species_list.csv`, `Tier2_species_list.csv`, `Tier3_species_list.csv`
  - Retain `tier_source` column tracking the origin of each entry throughout
  - Expected total before deduplication: ~350–600 entries

- [ ] **4.2 — Resolve synonyms via WoRMS**
  - Use `taxize::get_wormsid()` to get WoRMS taxon IDs for all entries
  - WoRMS flags synonyms and resolves them to current accepted names
  - Where entries differ only in taxonomic resolution (genus-level vs. species-level for the same organism), keep the most specific

- [ ] **4.3 — Get full taxonomic hierarchies**
  - Use `taxize::classification(db = "worms")` for all accepted names
  - Extract: Kingdom, Phylum, Class, Order, Family, Genus, Species for every entry
  - This is the core content of the Stage 1 CSV

- [ ] **4.4 — Format to Stage 1 CSV**
  - Apply exact column names and data types confirmed in Step 0.2
  - Add `is_marine = TRUE` flag for all entries
  - Retain `tier_source` as an annotation column
  - QC check: no missing taxonomic levels, no duplicate WoRMS IDs
  - Output: `Data/processed/South_Coast_Species_Master.csv`

- [ ] **4.5 — Document all decisions**
  - Record: species count per tier, what was dropped and why, resolution decisions for ambiguous aggregations
  - Save as `Data/processed/South_Coast_Species_Master_Notes.md`

---

## Phase 5: Prepare RAG Documents

*Local knowledge documents that the AI uses to find south coast-specific diet information.*

- [ ] **5.1 — Create RAG documents folder:** `Data/RAG_Documents/`

- [ ] **5.2 — Copy in the following documents (in order of relevance):**
  - Yang MSc thesis — Timor-Leste marine fisheries
  - Conservation International 2013 Timor-Leste reef report
  - NOAA 2017 south coast report
  - Lopez-Angarita et al. 2019 (PeskAAS methods — contains south coast species ecology)
  - Fulton et al. 2018 Great Australian Bight EwE model paper (regional trophic reference)
  - Spillias et al. 2025 (the AI-EwE-Diets paper itself — meta-reference for the method)
  - Any Ecobase 405 diet composition documentation

- [ ] **5.3 — Configure RAG system**
  - Follow the repo's instructions for pointing the RAG system at `Data/RAG_Documents/`
  - The system converts PDFs to searchable chunks automatically (LlamaParse)
  - Run a test query to verify document processing works cleanly

---

## Phase 6: Configure and Run the AI Pipeline (Stages 2–5)

- [ ] **6.1 — Write the research focus string**

  Use the following (edit as needed before running):

  > *"Small-scale, multi-gear coastal fisheries on a shallow tropical shelf (0–200m) in Timor-Leste, Southeast Asia. The fishery targets demersal reef fish and small pelagics. Keep the following as separate functional groups: snappers (Lutjanidae), trevally and jacks (Carangidae), sardines and herrings (Clupeidae), mackerel scad, tuna, sharks. Sea cucumbers are harvested and ecologically important — keep as a separate group. Dugongs and sea turtles are present and ecologically significant. For other taxa, broader functional groupings are acceptable."*

- [ ] **6.2 — Customise the grouping template**
  - Start with the 63-group default template (Table S1 of the Spillias et al. paper)
  - Add south coast-specific groups: sea cucumbers, mangrove-associated fish (if warranted by literature)
  - Remove clearly irrelevant groups: Antarctic krill, ice-associated fauna, cold seep communities, hydrothermal vent communities
  - Save as `Data/processed/South_Coast_Grouping_Template.csv`

- [ ] **6.3 — Run Stage 2: Data Harvesting**
  - Input: `South_Coast_Species_Master.csv`
  - Queries FishBase/SeaLifeBase (PARQUET files via DuckDB) and GLOBI API for each species
  - Expected runtime: 1.5–3 hours (~0.7 seconds per species × 500–800 species; most time is database downloads)
  - Monitor for API errors; the repo uses exponential backoff but may need manual retry for failed species

- [ ] **6.4 — Run Stage 3: AI Species Grouping**
  - Input: Stage 2 enriched species list + grouping template + research focus string
  - Claude performs hierarchical classification (Kingdom → Species, resolving only where needed)
  - Expected runtime: ~20–30 minutes
  - Output: species-to-group assignments + detailed grouping report for human review

- [ ] **6.5 — Run Stages 4 and 5: Diet Collection and Matrix Construction**
  - Stage 4: RAG searches + GLOBI synthesis per functional group (~15–30 minutes)
  - Stage 5: two LLM calls to draft and standardise diet proportions into matrix format (~5–10 minutes)
  - Output: `Data/processed/South_Coast_Diet_Matrix_Draft.csv`

---

## Phase 7: Human Review and Refinement

*The critical step. The AI produces a starting point; ecological judgment produces the final matrix.*

- [ ] **7.1 — Review the grouping report**
  - Read the AI's classification decisions for every taxon
  - Flag any ecologically incorrect assignments
  - Focus review on: PESKAS commercial groups (grouped as intended?), shark/ray groups, invertebrates, any borderline "RESOLVE" decisions
  - Estimated effort: 2–4 hours

- [ ] **7.2 — Check single-species management groups**
  - Verify snappers, trevally, sardines, tuna, and sea cucumbers are maintained as separate functional groups
  - The AI has a known bias toward lumping these into broader groups — if lumped, manually override and re-run Stage 5 for affected groups

- [ ] **7.3 — Cross-check diet proportions against PESKAS catch composition**
  - Use PESKAS metier analysis output and CPUE species composition as a reality check
  - If AI-assigned diet proportions contradict what the fishing gear data implies about feeding ecology, flag for manual adjustment
  - Example: if the AI assigns shallow demersal fish a diet of 40% zooplankton but all catch of this group is on baited demersal hooks, that's implausible

- [ ] **7.4 — Review ecologically implausible interactions**
  - Scan for: high-trophic predators feeding heavily on primary producers; prey items too large for the predator group; interactions that contradict south coast ecological knowledge
  - The AI adds ~14.5% of interactions not in expert matrices — each of these needs a check: plausible but unknown, or spurious?

- [ ] **7.5 — Document all manual changes**
  - For every change: record what was changed, from what value, to what value, and why
  - This becomes the audit trail for diet matrix provenance — required for EwE model documentation and peer review

- [ ] **7.6 — Produce the final diet matrix**
  - Apply all corrections
  - Verify all rows (prey) sum to 1.0 for each column (predator) — Ecopath requires this
  - Export as `Data/processed/South_Coast_Diet_Matrix_Final.csv`
  - This is the input to `Code/EwE_Input_Builder.R`

---

## Summary

| Phase | Scripts | Key Output | Estimated Effort |
|---|---|---|---|
| 0. Setup | — | Framework configured, format confirmed | 2–3 hrs |
| 1. Tier 1 | `Tier1_Species_Compilation.R` | `Tier1_species_list.csv` (~150–250 spp) | 3–5 hrs |
| 2. Tier 2 | `Tier2_Reference_Model.R` | `Tier2_species_list.csv` (~20–40 groups) | 1–2 hrs |
| 3. Tier 3 | `Tier3_OBIS_Supplement.R` | `Tier3_species_list.csv` (~100–300 spp) | 2–3 hrs |
| 4. Merge | `Species_List_Merge.R` | `South_Coast_Species_Master.csv` | 2–3 hrs |
| 5. RAG prep | Manual curation | RAG documents folder ready | 1 hr |
| 6. AI pipeline | AI-EwE-Diets (Stages 2–5) | `South_Coast_Diet_Matrix_Draft.csv` | 3–5 hrs (largely automated) |
| 7. Review | Manual + existing scripts | `South_Coast_Diet_Matrix_Final.csv` | 4–8 hrs |
| **Total** | | | **~18–30 hrs** |

---

## Prerequisites Before Starting

These conditions should be met before Phase 1 begins:

- **Alex's BRUV data** must be in a usable format in `Data/raw/Biological/`
- **PESKAS data quality check** (Step 1 of CLAUDE.md workflow) should ideally be completed first — confirms which PESKAS taxa are reliable before building Tier 1. Can proceed without it, but flag any PESKAS taxa with known data quality issues when compiling Tier 1
- **Ecobase 405 reference model** must be queryable via `Code/Ecobase.R`

---

## Key Decisions to Revisit Before Starting

- Should the PESKAS data quality check run first, or use the PESKAS species list as-is for Tier 1?
- Are the three tier scripts kept separate (cleaner audit trail) or combined into a single `Diet_Matrix_Species_List.R` with labelled sections?
- Are there any known south coast species that should definitely be in the model but are not captured by any of the three tiers?

---

## Connection to Other Workflows

- **Diet matrix → network resilience analysis:** The trophic flow matrix output from the balanced Ecopath model (derived from this diet matrix) feeds into the βeff resilience calculation in `IBF_South_Coast/Code/Resilience_Analysis/Network_Resilience.R` — see `IBF_South_Coast/CLAUDE.md` for details
- **Diet matrix → EwE model build:** This diet matrix is one of the core inputs to `Code/EwE_Input_Builder.R` alongside biomass estimates, P/B, Q/B, and catch data
