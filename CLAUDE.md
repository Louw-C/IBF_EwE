# IBF_EwE — Project Context

Ecopath with Ecosim (EwE) model for the south coast of Timor-Leste.
Part of the Ikan Ba Futuru (IBF) project, funded by WorldFish.
Goal: build a mass-balance trophic model of the south coast ecosystem to support fisheries and ecosystem-based management.

R project. Git repo linked to GitHub (Louw-C). Only `Code/` is committed to git.

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
| `Environmental/` | Chlorophyll-a (MODIS), SST and temperature records (NOAA), seawater chemistry — these are primary production inputs for the EwE model |
| `Reference_models/` | Ecopath reference model input/output data from comparable systems (e.g. Australian NW Coast) |
| `Taka_Survey_2024/` | Allen Coral Atlas 2024 habitat and bathymetry dataset — user guides, methods PDFs, data licences |

- **Rule:** files named with source prefix and date where applicable (e.g. `NOAA_Fish_Biomass_Timor_2013.csv`)

### `Data/processed/`
Analysis-ready datasets produced by R scripts.
- **Add here:** cleaned and formatted data files read directly into EwE model inputs or analysis scripts
- **Currently empty** — will populate as data processing scripts are run

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
| `Group_Matrix.xlsx` | Functional group matrix for the EwE model |
| `Existing data.xlsx` | Inventory of available data by functional group |
| `Potential model data_Sept 2024.xlsx` | Early-stage data gap assessment |

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
