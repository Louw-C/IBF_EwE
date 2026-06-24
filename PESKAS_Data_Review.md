# PESKAS South Coast Data Review
**Date:** June 2026  
**Data coverage:** 2018 – March 2025 | Covalima, Ainaro, Manufahi, Viqueque

---

## Executive Summary

The south coast PESKAS data covers 12,481 landing events across four municipalities. Three gears account for virtually all recorded fishing activity — **long line**, **hand line**, and **gill net** — and two habitat categories dominate: **Deep** and **Reef**.

Despite this limited diversity in gear and habitat, there are important recording inconsistencies that affect how these categories can be interpreted. Long line and hand line are not always clearly distinguished: Manufahi records zero long line across all years, and Viqueque 2018 recorded hand line almost exclusively before long line became the dominant category from 2019 onward. The taxon frequency profiles of Deep and Reef are near-identical across all gear types, raising questions about whether these labels describe genuinely different fishing grounds or reflect inconsistent recording by individual enumerators.

**Small pelagics dominate the catch record.** Mackerel scad and sardines dominate landings. This is broadly expected for a tropical nearshore fishery, but the gear and habitat assignments for these species are currently ambiguous. Planktivores appearing in nearly half of hand line and long line landings are likely caught on sabiki rigs — a gear type that is not recorded as a distinct category in PESKAS. The habitat field does not reliably distinguish open-water pelagic fishing from reef or bottom fishing, making it difficult to correctly assign these landings.

**Larger demersal species appear underrepresented.** Snapper, grouper, emperor, and jobfish — ecologically important and commercially significant species — are recorded at lower landing frequencies than expected and anecdotally observed. A likely contributing factor is that enumerators arrive at landing sites after the larger, higher-value fish have already been sold, introducing a systematic recording bias toward smaller and lower-value taxa.

**Implications for metier development.** Despite these caveats, the broad gear × taxon × habitat patterns can be used to define a working set of fishing metiers for the south coast. Long line/hand line targeting dermersal predators in deep water, sabiki rigs targeting small pelagics and indiscriminate gill netting in nearshore habitats, emerge as coherent and ecologically distinct fisheries. Formal metier definition, however, requires clear operational definitions of gear types — particularly the status of sabiki rigs — and habitat categories — particularly the boundary between Deep and Reef — before classification can be finalised.

A **métier** is defined as a group of fishing operations targeting a similar assemblage of species, using similar gear, in the same season or in the same area — characterised by a similar exploitation pattern (Ulrich et al., 2012). For the south coast of Timor-Leste, métiers will be defined using three dimensions: **gear type**, **habitat**, and **target taxon group**. Where these three dimensions produce consistent and ecologically coherent groupings in the PESKAS data, they will form the fleet structure for the EwE model. Catch proportions per métier will be used to estimate relative biomass contributions of each fleet. Once métiers are formalised, catch per métier and seasonal patterns in fishing activity will be examined to inform temporal dynamics in the EwE model.

---

## Background

We are developing an Ecopath with Ecosim (EwE) model for the south coast of Timor-Leste as part of the Ikan Ba Futuru (IBF) project. A core requirement of the model is a defined fleet structure — a set of fishing metiers (gear × target species × habitat) that group landings into ecologically and operationally coherent units. Getting this right matters for two reasons: (1) it supports the identification of important taxa and key functional groups; and (2) it identifies the most prominent fisheries on the south coast of Timor-Leste to incorporate into the EwE model.

PESKAS provides the most detailed fisheries data currently available for the region. Before we formalise any metier structure, we need to understand what the data can and cannot tell us — particularly where field recording choices may affect how we interpret gear type, habitat, and catch composition. This report summarises what we found across three phases of data exploration and lists the questions we need your input on before we proceed.

---
## Dataset

| Item | Detail |
|---|---|
| Source file | `PESKAS_timor_cpue_2018_mar2025.csv` |
| Geographic scope | South coast: Covalima, Ainaro, Manufahi, Viqueque |
| Unique landing events (raw) | 12,512 |
| Total rows | 221,258 (long format — one row per taxon slot per landing, incl. zeros) |
| Taxon groups recorded | 44 (of 59 in the lookup table) |
| Taxon lookup | `Peskas groups_From Lore.csv` |

**Data exclusions:** Gear types and habitat types with fewer than 20 landing events were excluded from Step 1 onwards to focus on general patterns. All landing events were counted for this threshold, including zero-catch records, as these represent real fishing trips. This removed 31 landing events — 0.25% of the 12,512 south coast landings. **All analyses in this report — including the zero-catch exploration — are based on the 12,481 retained landing events.** Categories with fewer than 20 landings are excluded from every figure and summary table.

| Type | Category | Ainaro | Covalima | Manufahi | Viqueque | Total | % of all landings |
|---|---|---|---|---|---|---|---|
| Gear | Cast net | — | 3 | — | 4 | 7 | 0.06% |
| Gear | Manual collection | — | 10 | 1 | 6 | 17 | 0.14% |
| Gear | Seine net | — | — | — | 3 | 3 | 0.02% |
| Gear | Spear gun | — | — | — | 1 | 1 | 0.01% |
| Habitat | Mangrove | 2 | — | — | — | 2 | 0.02% |
| Habitat | Seagrass | — | — | — | 5 | 5 | 0.04% |

---

## Step 1: Sampling effort and data coverage

**What we did:** Counted unique landing events (not rows) by municipality, year, and month. Examined gear and habitat composition over time. 

**Why:** Coverage gaps, sudden composition shifts, and recording anomalies can easily be mistaken for genuine ecological trends. We needed to know where and when monitoring was actually happening before interpreting any catch data.

**What we wanted to find out:** Which municipality × year combinations have reliable coverage? Are there monitoring gaps, gear reclassification events, or data entry anomalies that should be treated with caution?

### Key findings

The south coast data has important coverage gaps and several recording anomalies that need to be understood before any trend analysis is attempted.

**Figure 1a — Monthly landing events by municipality**

![Figure 1a: Monthly landing heatmap](Figures/PESKAS_1a_landing_events_monthly_heatmap.png)

*Grey cells = no landings recorded. Reveals monitoring gaps alongside year-to-year coverage.*

- **Manufahi 2022**: zero landings — a complete monitoring gap across all 12 months.
- **Ainaro**: absent from 2024 onward; declining from 136 landings (2019) → 93 (2021) → 23 (2023).
- **Covalima**: unexplained swings — 2,024 landings (2021) → 272 (2023) → 646 (2024).

**Figure 1b — Gear coverage by municipality and year**

![Figure 1b: Gear coverage](Figures/PESKAS_1b_gear_coverage.png)

*Unique landing events by gear type. Y-axes free — municipalities differ greatly in monitoring effort.*

A clear geographic split: Ainaro and Manufahi record only hand line and gill net (no long line in any year), while Covalima and Viqueque are long-line dominant. Viqueque 2018 records 248 hand line landings and zero long line — the inverse of all subsequent years.

**Figure 1c — Habitat coverage by municipality and year**

![Figure 1c: Habitat coverage](Figures/PESKAS_1c_habitat_coverage.png)

*Shifts in habitat composition over time may reflect enumerator changes rather than real behavioural shifts.*

Two habitat recording anomalies are apparent. First, Ainaro shows an abrupt switch from almost exclusively Reef in 2019 to 100% Deep from 2021 onward — this is explored in detail in Step 3. Second, Manufahi records Reef as the dominant habitat across all years, which is inconsistent with the limited reef habitat known to exist in that municipality from field observations; Reef may be functioning as a default label when the actual fishing ground does not fit another category.

---

## Step 2: Gear × taxon catch frequency

**What we did:** For each of the three main gears (long line, gill net, hand line), we calculated the proportion of landings where each taxon was caught — both across the south coast overall and faceted by municipality. We also flagged gear–taxon combinations that are ecologically implausible given how each gear works.

**Why:** Gear type is the primary dimension of any metier. We needed to know which taxa each gear actually catches, and whether catch profiles differ meaningfully across municipalities. If the same taxa appear under different gears in different places, that may point to enumerator-level inconsistency rather than genuine gear-specific targeting.

**What we wanted to find out:** Does each gear have a distinct catch profile? Are there taxa appearing under gears that cannot realistically catch them?

### Key findings

**Figure 2a — Gear × taxon catch frequency (south coast overall)**

![Figure 2a: Gear × taxon overall](Figures/PESKAS_2a_gear_taxon_overall.png)

*% of landings where each taxon was caught, by gear. Numbers = landing counts. Catch frequencies only — not catch weight.*

Long line dominates the south coast and shows a demersal-predator profile as its primary signal: Snapper/seaperch, Grouper, Emperor, Jobfish, and Sharks are the core catch, with large pelagics (Jacks/Trevally, Short-bodied mackerel, Tuna/Bonito) also prominent. However, Mackerel scad appears in 30% of long line landings and Sardines/pilchards in 24% — both are planktivores that cannot take a baited hook in these numbers. This is ecologically implausible for a set-line and points to **sabiki rigs** (multi-hook feather jigs used to catch baitfish) being fished alongside long line gear and recorded as part of the same trip, rather than as a distinct gear type.

Gill net shows a distinct small-pelagic profile: Garfish, Sardines/pilchards, Wolf herring, and Flying fish dominate. This is ecologically coherent.

Hand line shows the same sabiki flag as long line: **Mackerel scad appears in 48% of hand line landings and Sardines/pilchards in 21%** — planktivores that cannot take a baited hook in these numbers. Across both long line and hand line, the consistent presence of small pelagics at high frequencies strongly suggests sabiki rigs are recorded as part of these gear trips rather than as a distinct gear type. Whether all small pelagic records under long line and hand line should be treated as sabiki catches, or whether some proportion represent genuine incidental take, is a key question for the PESKAS team (see Q5).

**Figure 2b — Gear × taxon catch frequency by municipality**

![Figure 2b: Gear × taxon by municipality](Figures/PESKAS_2b_gear_taxon_by_municipality.png)

*% of landings in each gear × municipality that caught each taxon. Grey = gear not used in that municipality.*

Manufahi is the main outlier: hand line accounts for 83% of landings and zero long line is recorded in any year, despite long line being the dominant gear in the other three municipalities. Across all municipalities, the taxon discrepancies identified above persist — the same planktivores appear under gears that cannot realistically target them, regardless of location. This consistency suggests the issue reflects a systematic recording pattern (sabiki gear not recorded as a distinct type) rather than municipality-specific enumerator error.

---

## Step 3: Habitat × gear × taxon

**What we did:** Examined the habitat field across municipalities, gear types, and taxon groups. Tested whether habitat categories produce ecologically distinct catch profiles by comparing the taxon frequency profiles of "Deep" and "Reef". Tracked habitat composition over time within each municipality to detect recording shifts.

**Why:** Habitat is the third dimension of a metier and, for EwE, links catch groups to the correct functional group habitat assignments. But habitat is only useful if it reflects where fishing actually occurred — not where the boat departed from, or what the enumerator defaulted to when unsure.

**What we wanted to find out:** Does the habitat field reflect the actual fishing ground? Are "Deep" and "Reef" ecologically distinguishable? Are there abrupt shifts in habitat recording over time that suggest enumerator changes rather than real behavioural shifts?

### Key findings

**Figure 3a — Habitat composition by municipality**

![Figure 3a: Habitat × municipality](Figures/PESKAS_3a_habitat_municipality.png)

*% of landing events per municipality. "Deep" dominates across all four municipalities.*

"Deep" accounts for the large majority of south coast landing events across all four municipalities and all gear types. It is unclear what "Deep" as a habitat entails and what the difference is between "Deep" and "Reef".

**Figure 3b — Taxon catch frequency by habitat**

![Figure 3b: Habitat × taxon](Figures/PESKAS_3b_habitat_taxon.png)

*% of landings in each habitat where each taxon was caught. Numbers = landing counts.*

Multiple reef-obligate and shallow-water species appear under "Deep" at non-trivial frequencies: Parrotfish, Surgeonfish, Wrasse, Soldierfish, Fusilier, Moray, Crab, Octopus, Shrimp, and Milkfish. None of these are offshore deep-water species.

The taxon frequency profiles of "Deep" and "Reef" are highly correlated — broadly the same species appear at broadly the same rates under both habitat labels. The two categories are not producing ecologically distinguishable catch profiles. "Reef" also contains small open-water pelagics (Sardines/pilchards, Mackerel scad) that do not associate primarily with reef structure.

**Figure 3c — Gear × habitat combinations**

![Figure 3c: Gear × habitat](Figures/PESKAS_3c_gear_habitat.png)

*% of each gear's landings recorded in each habitat. Grey = combination not observed.*

Long line is strongly concentrated in Deep habitat, consistent with its demersal-predator profile. Gill net is more coastal, recorded predominantly under Reef and Beach. Hand line is distributed across habitats, reflecting its mixed catch profile. Beach seine landings are recorded almost entirely under Beach, as expected. The near-absence of any gear under FAD habitat (outside Viqueque 2018) is consistent with the anomalous FAD records that year being treated with caution.

**Figure 3d — Habitat composition over time by municipality**

![Figure 3d: Habitat over time](Figures/PESKAS_3d_habitat_over_time.png)

*Stable proportions = consistent recording. Sudden shifts indicate enumerator or protocol changes.*

Two anomalies stand out:

- **Ainaro**: ~99% "Reef" in 2019 → partially mixed in 2020 (73% Reef, 24% Beach) → 100% "Deep" from 2021 onward, with no Reef recorded at all. This is an immediate hard switch, not a gradual change. It coincides with declining monitoring effort and is consistent with an enumerator change, not a shift in fishing behaviour.

- **Viqueque 2018**: "FAD" accounted for 62.5% of Viqueque landings in 2018 (180 of 288), then dropped to 1.1% in 2019 and near-zero in all subsequent years. This year is already flagged for anomalous gear recording (all hand line, zero long line). The FAD-associated catch likely inflates pelagic species (Tuna, large Jacks) relative to all later years — Viqueque 2018 should not be used as a reference year.

---

## Questions for the PESKAS team

### A. Monitoring coverage

**Q1.** Manufahi 2022 has zero recorded landings across all months. Was this a monitoring gap (staff change, funding interruption) or data loss?

**Q2.** Ainaro is absent from 2024 and has been declining since 2021 (136 → 93 → 23 landings). Were landing sites dropped from the monitoring frame, or did monitoring stop altogether?

**Q3.** Covalima shows unexplained swings in landing counts: 2,024 (2021) → 272 (2023) → 646 (2024). Did the set of monitored landing sites change between these years, or is this an actual change in landings?

**Q4.** Given the monitoring gaps and ramp-up periods identified above, which years and municipalities do you consider to have sufficiently consistent and representative coverage to include in the metier analysis? Are there sampling periods that should be excluded or treated with caution?

### B. Gear classification

**Q5.** Does the PESKAS recording protocol have a category for sabiki rigs (multi-hook feather jigs used to catch baitfish)? Mackerel scad and Sardines/pilchards appear in 48% and 21% of hand line landings, and 30% and 24% of long line landings — both are planktivores that cannot take a baited hook in these numbers. Are sabiki rigs recorded as hand line, as part of a long line trip, or not recorded at all?

**Q6.** Manufahi records zero long line across all years, yet long line dominates elsewhere on the south coast. Do Manufahi fishers use set lines at all? If yes, how do enumerators decide whether to record a trip as hand line vs long line?

**Q7.** Viqueque 2018 records 248 hand line landings and zero long line. From 2019 onward, long line dominates and hand line drops to near-zero. Was this a first-year recording inconsistency, or did gear use genuinely change between 2018 and 2019?

**Q8.** Could you provide brief operational definitions for each gear type in PESKAS? 

### C. Habitat classification

**Q9.** What does "Deep" mean in the PESKAS habitat field? Does it refer to (a) water depth fished (if so, what threshold?), (b) distance from shore, (c) substrate type such as rocky or sandy bottom below the reef crest, or (d) a residual default used when the fishing ground does not fit Reef, Beach, Mangrove, or Seagrass? The taxon profiles suggest it may not mean open offshore water.

**Q10.** Is there a formal protocol definition distinguishing "Deep" from "Reef"? The catch profiles of these two habitat types are very similar — broadly the same species appear at broadly the same rates under both labels. Is it possible that individual enumerators apply these labels differently?

**Q11.** When a "Reef" landing includes Sardines/pilchards or Mackerel scad, did the boat fish over reef structure, or did it depart from a reef-adjacent site and then fish in open water? When a "Beach" landing includes Snapper, Grouper, or Emperor, was the catch from a shallow inshore zone or from a boat that launched from the beach?

**Q12.** Ainaro switched from ~99% "Reef" in 2019 to 100% "Deep" from 2021, with an abrupt transition. Was there an enumerator change in Ainaro between 2020 and 2021? If so, do the two enumerators apply different definitions of "Reef" vs "Deep"? The pre-2021 Reef records and the post-2021 Deep records may describe the same fishing grounds under different labels.

**Q13.** "FAD" accounted for 62.5% of Viqueque landings in 2018, then near-zero from 2019 onward. Was a FAD deployed near Viqueque in 2018 and then removed or lost?

---