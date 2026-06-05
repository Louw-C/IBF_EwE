# IBF_EwE — Project Context

Ecopath with Ecosim (EwE) model for the south coast of Timor-Leste.
Part of the Ikan Ba Futuru (IBF) project, funded by WorldFish.
R project. Git repo linked to GitHub (Louw-C). Only `Code/` is committed to git.

---

## Project Introduction

The south coast of Timor-Leste has a relatively shallow, productive continental shelf (5–17 km wide, <200 m depth) that supports small-scale coastal fisheries across three municipalities: Manufahi, Ainaro, and Covalima. A fourth municipality, Viqueque, is also included in PESKAS catch data and should be considered for model coverage. Limited ecological data exist for this coastline. Catch monitoring has been conducted via PESKAS since 2018 and Blue Ventures since approximately 2020, but no fisheries-independent stock assessments or ecosystem models have been built for the south coast.

The EwE model will provide:
- A mass-balance snapshot of the current ecosystem state (standing biomass, trophic flows, fisheries removals)
- A platform for modelling future scenarios under climate change, population growth, and development (linking to IBF_ADWIM scenarios and IBF_South_Coast synthesis)
- Biomass estimates by functional group that ground-truth and complement the BRUV survey data (IBF_BRUVs)

This model is framed within an ecosystem-based fisheries management (EBFM) approach. Rather than targeting individual species, EBFM considers functional groups, trophic interactions, and ecosystem structure — appropriate for the multi-species, multi-gear small-scale fisheries of the south coast.

The EBF index framework (Lenfest document, Fulton papers, FAO toolbox) and the TL south coast EBF index document are developed in **`IBF_South_Coast/`** — that is the integrating project where EwE outputs, BRUV data, PESKAS data, and ADWIM all come together.

---

## Study Area and Ecosystem Boundaries

- **Area:** South coast continental shelf from the coastline to the shelf/slope break at ~200 m depth — approximately **780 km²**
- **Municipalities:** Manufahi, Ainaro, Covalima (core IBF sites); Viqueque included in PESKAS data and should be considered
- **Depth focus:** The shelf is relatively wide and shallow compared to the north coast — this is the productive zone for demersal and coastal pelagic species
- **Habitats:** Fringing reef, intertidal, sandy/soft sediment shelf — to be defined based on habitat mapping data (IBF_BRUVs dropcam survey; Allen Coral Atlas; Taka survey data)

The model area boundaries align with IBF_BRUVs (which surveys to 100 m depth) and IBF_South_Coast (which uses the same shelf system as its analysis unit).

---

## The Ecopath with Ecosim Framework

### Ecopath (static, mass-balance)
Ecopath models the ecosystem at a single point in time as a set of functional groups linked by trophic flows. The master equation for each group *i* is:

> **P_i = Y_i + (B_i × M2_i) + E_i + BA_i + P_i × (1 − EE_i)**

Where:
- **P_i** = total production (biomass produced per year)
- **Y_i** = fishery catch (removed by fishing)
- **B_i × M2_i** = predation mortality (biomass consumed by predators)
- **E_i** = net migration (emigration − immigration)
- **BA_i** = biomass accumulation (positive if population growing)
- **P_i × (1 − EE_i)** = other mortality (EE = ecotrophic efficiency — proportion of production used within the system)

**Required inputs per functional group:**
| Parameter | Symbol | Description |
|---|---|---|
| Biomass | B | Mass per unit area (t/km²) |
| Production/Biomass ratio | P/B | Equivalent to total mortality (Z); per year |
| Consumption/Biomass ratio | Q/B | Food intake rate; per year |
| Ecotrophic efficiency | EE | Proportion of production consumed within model — usually estimated by model |
| Diet composition | DC | Proportion of each prey in the diet (must sum to 1) |
| Catch | Y | Fisheries landings per unit area (t/km²/yr) |

Note: diet composition for functional groups will be sourced from the literature and comparable models. No site-specific diet assessments will be conducted for TL.

### Ecosim (dynamic, temporal)
Once the Ecopath model is balanced, Ecosim allows temporal simulation of how the ecosystem responds to changes in fishing pressure, climate forcing, or management interventions. Future scenario modelling (2030, 2050, 2090) will use Ecosim with forcing functions derived from IBF_ADWIM driver projections.

### Reference models
Comparable EwE models will be used to fill data gaps and cross-check parameter estimates. The primary reference is the **Australian Northwest Shelf** model (Ecobase model 405), chosen for its similar shelf environment and tropical demersal/pelagic assemblage structure. Additional references available via Ecobase — see `Code/Ecobase.R`.

---

## Conceptual Model

Before building the quantitative Ecopath model, a qualitative **conceptual model** (fuzzy cognitive map) will be developed using **Mental Modeler** (Gray et al., 2012; mentalmodeler.com). This maps the key ecosystem components, their connections, and the direction and strength of those connections (−1 to +1 scale).

The conceptual model will:
- Define nodes: functional groups, environmental drivers, fisheries, social/economic factors
- Define relationships: direction (positive/negative) and magnitude of influence between nodes
- Allow scenario simulation: how does a change in one component propagate through the system?

Mental Modeler files (.mmp) and notes are stored in `Writing/Concept_models/`. The conceptual model is a prerequisite for the Ecopath build — it defines the functional group list and key trophic linkages before parameterisation begins.

---

## Functional Group Development

This is the critical first step before any model parameterisation. The goal is to define a functional group list that:
- Captures ecologically distinct groups (trophic role, habitat, life history)
- Reflects what is caught and observed in the south coast fishery
- Is supported by sufficient data for parameterisation
- Is not so fine-grained that data gaps become unmanageable

### Step 1 — PESKAS data investigation and quality checking

Before any grouping or metier decisions, do a thorough exploration of the PESKAS data structure to understand what is in the data, where it is reliable, and where it is likely to contain errors. The goal is to produce a set of clear summaries and figures that can be brought directly to the PESKAS team to ask targeted questions — not to draw conclusions, but to flag things that need clarification.

Use the **CPUE dataset** (`PESKAS_timor_cpue_2018_mar2025.csv`) for all investigation — it is at landing level and has gear, habitat, municipality, and 45+ taxa. The aggregated catch CSV is too coarse for this.

**Develop as `PESKAS_Data_Investigation.R` with clearly labelled sections and inline notes explaining what each output shows and what question it raises.**

#### 1a — Data overview and coverage

- How many landings are recorded per municipality, per year, per gear type, per habitat?
- Are all four south coast municipalities (Covalima, Ainaro, Manufahi, Viqueque) well covered across all years, or are some sparse?
- Which gear types and habitats are represented? Are there combinations that appear very rarely (low sample size = low confidence)?
- Output: summary table of sample sizes by municipality × gear × habitat × year. Flag any cell with <10 landings as low confidence.

#### 1b — Fish groups by gear type

For each gear type, summarise which catch groups are recorded and in what proportion:
- What does a typical "hand line" landing look like in terms of species composition?
- What does a typical "gill net" landing look like?
- What does a typical "long line" landing look like?
- Are there gear types that consistently catch the same narrow set of species (suggesting a defined target fishery), and gear types that catch a wide mix (suggesting opportunistic or multi-target fishing)?
- What fish types are caught by hand lines and long line?
- Do small pelagic catches vary across time/seasons?
- Output: heatmap of catch composition (%) by gear type; one chart per municipality to show regional variation

**Key question for PESKAS team:** What exactly does "hand line" mean in the field recording protocol — does it include sabiki rigs, feather jigs, or lures, or only baited single hooks? This matters because small planktivorous fish (sardines, mackerel scad) cannot take baited hooks, so their appearance under "hand line" suggests either a different gear is being used or catch is being mis-attributed to gear.

#### 1c — Fish groups by habitat

For each habitat type (Reef, Deep, Beach, FAD, etc.), summarise which catch groups are recorded:
- What species assemblage is associated with each habitat?
- Are there habitat-species combinations that are ecologically unlikely (e.g. tuna recorded as "Beach"; sardines recorded as "Reef")?
- How does habitat composition vary by municipality? (The same habitat code may mean different things in different places)
- Output: heatmap of catch group × habitat, showing proportion of each group's catch by habitat; flag ecologically implausible cells

**Key question for PESKAS team:** Does "habitat" describe where the boat fished, or where it departed from? Specifically — in municipalities where "Reef" landings show large proportions of open-water pelagic species, is the recorder logging the launch site rather than the actual fishing ground?

#### 1d — Ecological plausibility check (gear × species)

This is the core quality check. For each gear × species combination, assess whether it is ecologically plausible:

Build a reference table of expected gear × species compatibility:

| Gear | Ecologically expected catch | Ecologically unlikely catch |
|---|---|---|
| Hand line (baited) | Snappers, groupers, emperors, jacks, jobfish, barracuda | Sardines, mackerel scad, fusiliers, parrotfish, surgeonfish |
| Long line (demersal) | Snappers, groupers, sharks, emperors, jobfish | Sardines, mackerel scad, parrotfish, surgeonfish |
| Gill net | Broad range — pelagic to demersal; garfish, sardines, tuna, sharks, rays | Few absolute exclusions, but check proportions |
| Beach seine | Sardines, small nearshore pelagics | Reef fish, large predators |
| FAD | Mackerel scad, tuna, jacks | Benthic species |
| Spear | Reef fish, octopus | Pelagic species |

Calculate what proportion of landings for each gear type contain ecologically unlikely species. Flag combinations where the "unlikely" catch is substantial (e.g. >10% of landings for that gear). Visualise as a heat map: gear × species group, colour = proportion of landings, with ecologically implausible cells highlighted.

**Key outputs for PESKAS team discussion:**
- "X% of hand line landings record sardines or mackerel scad — are these caught on sabiki rigs or similar multi-hook gear?"
- "Y% of long line landings record parrotfish — are these from a separate method (spearing) on the same trip, or a recording error?"
- "Reef habitat in Manufahi is 86% pelagic species — does 'Reef' here mean the fishing ground or the launch site?"

#### 1e — Temporal patterns and anomalies

- Do catch totals or compositions show sudden jumps between years that are hard to explain ecologically? These may reflect changes in sampling effort or methodology rather than real fishery changes
- Are there municipalities with very high interannual variability that may indicate data collection issues?
- Output: time series of catch by group for each municipality; flag obvious anomalies with a note

**Key question for PESKAS team:** For municipalities or years with large unexplained swings in catch estimates, were there changes in the number of landing sites monitored, the raising methodology, or the field staff involved?

#### 1f — Compile questions for PESKAS team

At the end of the script, produce or document a structured list of questions arising from the investigation, each paired with the figure or table that prompted it. The aim is to go into a conversation with the PESKAS team (Lorenzo Longobardi or Lore) with specific, evidence-backed questions rather than general queries.

Format per question:
- **What we found:** brief description of the pattern
- **The figure:** which output to show
- **The question:** what we need to know to interpret it correctly
- **Why it matters:** how the answer affects the EwE model or metier classification

---

### Step 2 — PESKAS data analysis and fisheries metier identification

PESKAS provides fisheries-dependent catch monitoring across all south coast municipalities since 2018 (data from Lore, updated March 2025). Focus municipalities: **Covalima, Ainaro, Manufahi, Viqueque**.

**PESKAS files available (`Data/raw/Fisheries/`):**

| File | Contents |
|---|---|
| `PESKAS_timor_catch_2018_mar2025.csv` | Monthly aggregated catch by municipality; **13 taxon codes only** (BEN, CGX, CJX, CLP, FLY, GZX, LWX, MOO, MZZ, RAX, SDX, SNA, TUN) |
| `PESKAS_timor_cpue_2018_mar2025.csv` | **Landing-level records** with gear type, habitat, landing site, CPUE — richer than the aggregated catch file; contains more taxon codes |
| `PESKAS_timor_length_2018_mar2025.csv` | Length frequency data by species from landings |
| `PESKAS_timor_boats_2021:22.csv` | Boat registration data by municipality (2016 and 2021/22) |
| `Peskas groups_From Lore.csv` | **Full PESKAS species classification — 57+ groups** with ISSCAAP codes, interagency codes, family, Tetum names |
| `Raw_SAU EEZ 626 v50-1.csv` | Sea Around Us catch reconstruction for TL EEZ |

**The 13 vs 57+ groups issue:**
The aggregated catch CSV contains only 13 taxon codes — a pre-filtered or pre-aggregated subset. The full PESKAS lookup (`Peskas groups_From Lore.csv`) has 57+ distinct catch categories. **Before restructuring any groupings:** map the 13 codes in the catch data against the full lookup table; determine what has been aggregated and what is absent. Also check whether the landing-level CPUE data contains additional taxon codes beyond the 13.

**Fisheries metier analysis:**

A metier is a defined fishing operation characterised by: gear type + target species group + habitat/area + season. Identifying metiers is essential for the EwE model fleet structure (each metier = a distinct fleet with its own catch composition and effort dynamics) and for understanding how the south coast fishery is actually organised.

Use the **CPUE dataset** (landing level) for metier analysis — it contains gear, habitat, landing site, catch taxon, trip length, and CPUE: all the variables needed. The aggregated catch CSV is too coarse for metier work.

**Analysis workflow — develop as `PESKAS_Metier_Analysis.R`:**

1. Filter CPUE data to south coast municipalities (Covalima, Ainaro, Manufahi, Viqueque); characterise coverage and sample sizes
2. Summarise gear types in use, habitats fished, and catch groups recorded — understand the structure of the data before analysis
3. Produce a **heatmap of catch/CPUE by catch group × municipality** — and separately by gear type, by habitat, and across time (year/season). Visualise how groups co-vary across space, gear, and time. Look for a demersal fishery vs small pelagics fishery pattern and other natural clusters
4. **Network or cluster analysis** to identify fishing operations that share similar target species combinations. Options:
   - Hierarchical clustering on trip-level catch composition profiles
   - k-means clustering on gear × catch group combinations
   - Co-occurrence network (species that co-occur in landings)
5. Based on clusters, define candidate **metiers** (e.g. "reef handline — demersal"; "gill net — small pelagics"; "beach seine — nearshore pelagics"). Each metier becomes a fleet in the EwE model.
6. For each metier: characterise dominant gear, primary target group(s), spatial distribution (municipalities/habitats), and seasonality
7. Identify which catch groups remain separate (e.g. snappers — distinct trophic role and management unit) and which can be combined (e.g. sardines + scad + mackerel → small pelagics)
8. Flag groups from the full 57+ classification that do not appear in the south coast landings — these may need to be estimated or treated as non-target groups in the model

**Things to keep in mind — data quality and interpretation (preliminary, needs verification):**

The following are considerations flagged during initial data exploration. Treat as hypotheses to test, not settled conclusions.

- **Sabiki rigs misclassified as hand lines.** Small pelagics (sardines, mackerel scad) appearing in "hand line" landings are almost certainly caught on sabiki rigs (multi-hook rigs with tiny hooks) or feather jigs — not true baited hand lines. Small planktivorous fish don't take baited hooks. When interpreting the CPUE gear field, "hand line + small pelagics" likely = sabiki/jigging. Verify with local fishers or the PESKAS team and consider reclassifying for the metier analysis.

- **The habitat field is unreliable.** "Reef" in the CPUE data may describe the launch point rather than the actual fishing ground. In some municipalities (e.g. Manufahi/Betano), the catch recorded under "Reef" is almost entirely pelagic species — ecologically inconsistent with a reef habitat. Treat the habitat field as indicative only. For assigning catches to EwE functional groups, use the species/taxon identity, not the habitat code.

- **SNA is a catch-all for many benthic predators.** The SNA (Snapper/seaperch) code likely aggregates true snappers (Lutjanidae) with emperors (Lethrinidae), groupers on soft/rocky substrate, sweetlips, and threadfin breams — all lumped because field recorders have limited species ID capacity. The south coast is not strongly coral-reef associated, so "snapper" catches here are likely a mix of sandy/rocky-bottom demersal species. The proportion of true snappers within SNA needs estimating from fisher surveys or market studies.

- **CGX (Jacks/Trevally) placement is debatable.** Jacks and trevally are active pelagic hunters and arguably belong in a large pelagic predators group rather than large benthic predators. Their placement significantly affects the balance between functional groups, given that CGX is one of the largest catch components on the south coast. Resolve by checking local fishing behaviour (do fishers target them on the bottom or in the water column?).

- **MOO (Moonfish) identity is uncertain.** "Moonfish" in TL could refer to batfish (Platax spp. — a reef-associated herbivore/omnivore) or pomfret (a pelagic species). These would go into completely different functional groups. Check with fishers or the PESKAS team what species "Baleu belar oan" (Tetum) actually refers to.

- **MZZ (Other) is a large black box.** At ~14% of south coast catch, the MZZ category contains unknown quantities of groupers, sharks, herbivorous reef fish, and invertebrates — all ecologically important groups that are invisible in the aggregated data. The landing-level CPUE data has better resolution and reveals additional taxa (sharks, groupers, emperors, parrotfish) hidden inside MZZ. Use CPUE species proportions to allocate MZZ catch across functional groups.

- **Viqueque dominates the south coast picture.** Viqueque accounts for roughly 60% of total south coast catch. Any combined "south coast" metric is heavily weighted by Viqueque's fishery character, which is more demersal/reef-associated than the other municipalities. Be aware of this when interpreting aggregate patterns and consider whether Viqueque's distinct fishery warrants separate treatment.

- **Absolute catch values carry high uncertainty.** PESKAS catch estimates are raised from ~2 tonnes of directly observed catch to thousands of tonnes using raising factors of ~3,000–4,000×. Proportional species composition is more reliable than absolute tonnage. Cross-check total catch against independent sources (SAU, FAO national statistics) before committing absolute values to Ecopath. SAU estimates for TL are themselves largely reconstructed and should be treated as broad order-of-magnitude checks only.

- **Caution with the NFS report south coast totals.** An official NFS fisheries report using PESKAS data may contain a bug where accent mismatches in municipality names (e.g. "Liquiça" vs "Liquica") cause north coast municipalities to be misclassified as South Coast, inflating south coast catch approximately 3×. If using the NFS report as a reference, verify its regional totals directly from the raw PESKAS data before accepting them.

**Reference resources:**
- fish-summarizer tool (GitHub: aakiona/fish-summarizer) — catch composition summary functions that may be adaptable
- López-Angarita et al. (2020) — documents the PeskAAS monitoring system; confirms sabiki hypothesis (hook sizes #4–18 recorded as "hand line"); notes most boats fish within 5 km of shore and 71% are non-motorised; gleaning catches not included in national production estimates
- MPA habitat use paper (Sciencedirect link, provided by user) — relevant for linking catch groups to habitats

**Outputs:**
- Catch and CPUE summary tables by group, municipality, gear, habitat, year
- Heatmap figures (catch/CPUE across groups × location × gear × time)
- Mapping table: PESKAS taxon codes → full classification → EwE functional groups
- Defined metier list (3–6 metiers) with gear, target group, area, effort characterisation
- These metiers feed directly into the EwE fleet structure

**Coding standard:** all steps with inline comments explaining each decision — what was done, why, and what the output means. This code is a documented analytical record, not just computation.

### Step 3 — Available survey data

Two sources of fisheries-independent survey data are available to supplement PESKAS:

**Alex's BRUV/survey data:**
- Group all snappers and jobfish into a snapper functional group; similarly aggregate other species into ecologically meaningful groups
- Calculate the **proportion of total biomass (or MaxN)** represented by each functional group across the full survey
- Use these proportions to validate or supplement PESKAS catch composition — the survey captures species that may be rarely caught but ecologically important

**NOAA surveys (2013–2014, 2016, 2018):**
- Fish biomass and benthic cover data available in `Data/raw/Biological/`
- Use to cross-check functional group presence and relative biomass estimates

**CTC and other reports (Manufahi MPA area):**
- Relevant reports (e.g. Conservation International 2013, NOAA 2017, Lopez-Angarita et al. 2019) may contain species lists and biomass estimates for south coast reefs
- Extract species/group information from these to supplement the functional group list and identify groups potentially missing from catch data

### Step 4 — Missing groups

Some ecologically important groups may not appear in catch data but need to be in the model:
- Groups not targeted by the fishery (e.g. apex predators, herbivores, planktivores)
- Groups observed during surveys but not landed (e.g. sea snakes, turtles, some sharks)
- Groups inferred from habitat and regional literature (e.g. mangrove-associated species)

Sources: fisher discussions, BRUV observations, benthic habitat mapping, regional literature.

### Step 5 — Benthic invertebrates and lower trophic levels

These groups will largely be estimated from secondary sources:

**Benthic invertebrates:**
- Use habitat mapping data (IBF_BRUVs dropcam survey; Allen Coral Atlas) to identify major benthic invertebrate communities present (corals, echinoderms, molluscs, crustaceans)
- Check Alongi et al. (2013) and similar papers for descriptions of nearshore benthic communities in the Timor-Leste/Coral Triangle region

**Primary production:**
- Use satellite-derived chlorophyll-a (Chl-a) data from **NASA Ocean Color** (freely available; MODIS-Aqua or VIIRS) to estimate net primary production (NPP) for the south coast area
- Extract Chl-a time series for the model bounding box (~8.5–9.5°S, 124.5–125.5°E)
- Raw Chl-a data stored in `Data/raw/Environmental/`

**Zooplankton:**
- Estimate zooplankton biomass from empirical relationships with primary production (standard EwE approach for data-limited systems)
- No site-specific zooplankton data available — use published empirical ratios from comparable tropical shelf systems

**Phytoplankton:**
- Primary producer group; biomass estimated from Chl-a using carbon:Chl-a conversion ratios
- P/B set to high value (reflecting fast turnover); B estimated from NPP and assumed P/B

---

## Shark and Ray Functional Groups

Sharks and rays are ecologically important apex predators that are likely underrepresented in catch data (low landing rates on south coast). Proposed groupings based on taxonomy and trophic role:

| Group | Taxa | Trophic role / notes |
|---|---|---|
| Hammerhead sharks | *Sphyrna lewini* | Apex predator; schooling; CITES listed |
| Requiem sharks | *Carcharhinus* spp. | Diverse apex/mesopredators; most common reef sharks |
| Mantas | Mobulidae | Filter feeders (zooplankton); very low P/B |
| Stingrays | Dasyatidae + *Rhinoptera* spp. | *Rhinoptera* is bentho-pelagic but feeds on benthic bivalves — specialist feeder, keep separate or note within ray group |
| Gulper sharks | *Centrophorus* spp. | Deep-water; may be outside model area but worth assessing |

Biomass estimates for these groups will require literature values — local data are unlikely to be sufficient.

---

## Data Requirements and Gaps

| Functional group category | B | P/B | Q/B | Diet | Catch data |
|---|---|---|---|---|---|
| Coastal pelagics (small) | Survey (Alex/NOAA) | Literature | Literature | Literature | PESKAS |
| Demersal fish (snappers, groupers) | Survey (Alex/NOAA) | Literature | Literature | Literature | PESKAS |
| Sharks and rays | Literature / estimates | Literature | Literature | Literature | Limited |
| Reef invertebrates | Habitat mapping / estimates | Literature | Literature | Literature | Minimal |
| Zooplankton | Empirical from NPP | Literature | Literature | Assumed | None |
| Phytoplankton | Chl-a derived | Literature | — | — | None |

For all groups where local data are insufficient, parameters will be drawn from the Australian NW Shelf reference model (Ecobase 405) and other comparable tropical shelf EwE models.

---

## Proposed R Code Workflow

All R scripts should include **inline documentation** — each analytical step should have a comment explaining what is being done and why. This makes the code a traceable analytical record, not just computation.

Scripts to develop (in approximate order):

| Script (proposed) | Purpose |
|---|---|
| `PESKAS_Data_Investigation.R` | Data coverage, gear × species and habitat × species summaries, ecological plausibility checks, anomaly flagging, structured question list for PESKAS team |
| `PESKAS_Metier_Analysis.R` | Map 13-group catch data against full 57+ classification; landing-level CPUE analysis; heatmaps; cluster/network analysis to define fisheries metiers |
| `PESKAS_Functional_Groups.R` | Assign PESKAS catch groups and metiers to EwE functional groups; proportional catch by group |
| `Alex_Survey_Groups.R` | Aggregate Alex's survey data into functional groups; calculate group proportions across full survey |
| `Primary_Production.R` | Process NASA Ocean Color Chl-a data; estimate NPP for model area; derive phytoplankton and zooplankton biomass |
| `Biomass_Estimates.R` | Compile biomass estimates per functional group from surveys, literature, and reference models |
| `EwE_Input_Builder.R` | Assemble final Ecopath input tables (B, P/B, Q/B, EE, diet matrix, catch) — the diet matrix (A_ij) and trophic flow outputs from this script feed directly into the network resilience analysis (βeff calculation) in `IBF_South_Coast/Code/Resilience_Analysis/` |

Existing scripts:
- `Ecobase.R` / `Ecobase_Code.R` — Ecobase reference model queries
- `EWE_Fish species data gathering.R` — species data compilation
- `Sea Around Us_Catch data.R` — SAU catch reconstruction
- `Comparing Peskas catch and FishMIP model_2018-2024.R` — FishMIP vs PESKAS comparison
- `Packages.R` — shared package loading

---

## Future Scenarios

Once the baseline Ecopath model is balanced, Ecosim will be used to model three time horizons:

| Horizon | Year | Rationale |
|---|---|---|
| Near-term | 2030 | Within planning cycle; ~5 years |
| Medium-term | 2050 | Infrastructure and policy lifetime |
| Long-term | 2090 | Intergenerational; aligns with RCP/SSP end-century |

Scenario drivers will be developed in collaboration with communities and government, and informed by the IBF_ADWIM driver projections (climate change, population growth, development). Tasi Mane oil/gas development on the south coast is a major planned scenario driver.

---

## Next Steps — Where to Start

1. **Develop `PESKAS_Data_Investigation.R`** — data coverage, gear × species and habitat × species heatmaps, ecological plausibility checks, and a compiled question list for the PESKAS team. This is the first task; do it before any grouping decisions.
2. **Contact PESKAS team** — bring figures and specific questions from Step 1 to clarify gear classification, habitat field meaning, and data anomalies before proceeding.
3. **Develop `PESKAS_Metier_Analysis.R`** — only after data quality questions are resolved; map the 13-group catch data against full 57+ classification; cluster/network analysis to define metiers.
4. **Agree on functional group list** — based on metier analysis + Alex's survey data + missing group assessment; produce a draft `Group_Matrix.xlsx`
4. **Build conceptual model** — once functional groups are agreed, build the Mental Modeler fuzzy cognitive map
5. **Begin parameterisation** — starting with groups where data are strongest (coastal pelagics from PESKAS; demersal fish from surveys)

---

## Folder Structure and Filing Rules

### `Code/`
R scripts in a flat structure — no subfolders. Scripts are largely independent.

**Current scripts:**
- `Ecobase.R`, `Ecobase_Code.R` — Ecobase database queries for reference model parameters
- `EWE_Fish species data gathering.R` — compiling species data for functional group definitions
- `Sea Around Us_Catch data.R` — processing SAU catch reconstruction data
- `Comparing Peskas catch and FishMIP model_2018-2024.R` — FishMIP vs PESKAS catch comparison
- `Packages.R` — package loading script used across analyses

- **Naming:** descriptive names; no mandatory numbering
- **Add here:** new R scripts as analysis progresses; keep Code/ flat

### `Data/raw/`
Original, unedited data. Never modify files here.

| Subfolder | What goes here |
|---|---|
| `Biological/` | NOAA benthic cover and fish biomass surveys (2013–2014), biomass survey data (2016, 2018), species lists, FishMIP model outputs |
| `Environmental/` | Chlorophyll-a (MODIS), SST and temperature records (NOAA), seawater chemistry — primary production inputs for the EwE model |
| `EwE_Reference_models/` | Ecopath reference model input/output data from comparable systems (e.g. Australian NW Shelf, Ecobase 405) |
| `Fisheries/` | PESKAS catch (monthly aggregated, 13 groups), CPUE (landing level, gear + habitat), length, boats registration; full PESKAS species lookup; SAU catch reconstruction |
| `Taka_Survey_2024/` | Allen Coral Atlas 2024 habitat and bathymetry dataset — user guides, methods PDFs, data licences |

- **Rule:** files named with source prefix and date where applicable (e.g. `NOAA_Fish_Biomass_Timor_2013.csv`)

### `Data/processed/`
Analysis-ready datasets produced by R scripts.
- **Add here:** cleaned and formatted data files read directly into EwE model inputs or analysis scripts
- **Current files:**
  - `Timor biomass survey 2016 and 2018.csv/.xlsx` — processed biomass survey data from NOAA surveys

### `Figures/`
Output graphics from R scripts.
- **Current files:** trophic level and food web diagrams for key functional groups (Jacks & Trevallies, Mackerel scad, Sardines/Herring, Snappers, Peskas groups)
- **Naming:** include species/group and figure type (e.g. `Snappers_Trophic levels.jpeg`)

### `Spatial/`
All GIS files — shapefiles, KMZ, KML.
- **Current files:** NOAA fish biomass and benthic cover shapefile; KMZ site files for Alex biomass survey and Alongi et al. 2013 sites
- **Rule:** prefix KMZ/KML files with `IBF_` if IBF-specific; use source prefix for external data (e.g. `NOAA_`)

### `Writing/`
Active working documents and model planning materials.

| Subfolder/File | What goes here |
|---|---|
| `Concept_models/` | Mental Modeler files (.mmp), concept model notes and images — qualitative model development |
| `Modeling steps.docx` | Step-by-step EwE model development workflow |
| `Some initial model notes.docx` | Early working notes on model scope and approach |
| `Group_Matrix.xlsx` | Functional group matrix for the EwE model — **to be developed** |
| `Existing data.xlsx` | Inventory of available data by functional group — **to be developed** |

- **Rule:** when a document is superseded, move old version to `Archive/` before saving the new one

### `Admin/`
Data documentation and non-analysis reference materials.
- **Current files:** NOAA README (data collection methods), NOAA benthic/fish biomass collection guide (PDF), nearshore biological environment report (Timor-Leste, 2004)
- **Add here:** data licences, data citation requirements, external consultant reports, data request correspondence

### `Literature/`
Reference PDFs for EwE model development.
- **Add here:** papers on Timor-Leste fisheries, Coral Triangle ecosystems, EwE methodology, trophic modelling
- **Current files:** Southeast Asia fisheries catch reconstruction, Timor-Leste coral reef and fisheries papers, SAU catch methods guide, Yang MSc thesis (TL marine fisheries)

### `Archive/`
Old versions, superseded documents, and intermediate outputs no longer in active use.
- **Add here:** old concept model drafts, superseded data files, old analysis versions

---

## Key Rules Summary

1. **Raw data is sacred** — nothing in `Data/raw/` is ever edited or deleted
2. **Environmental data lives here** — Chl-a and SST raw data stay in `Data/raw/Environmental/` as primary EwE production inputs; processed versions go in `Data/processed/`
3. **Only one current version** — latest document in `Writing/`; previous versions go to `Archive/`
4. **Code/ only in git** — all other folders are gitignored and stay local
5. **Shapefiles go in `Spatial/`** — not in `Data/` (even if produced by R)
6. **Data overlap with IBF_South Coast is fine** — fisheries data will be processed in IBF_South Coast first, then relevant outputs copied here when ready for model input
