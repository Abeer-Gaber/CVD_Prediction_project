# NHANES CVD ML Replication — Data Dictionary

Data dictionary for `nhanes_cvd_extract.rds`, produced by the multi-cycle extract
script. Replicates the variable set from *Interpretable Machine Learning for CVD
Risk Prediction: Insights from NHANES Dietary and Health Data* (PMC12591444),
extended across additional NHANES cycles.

Every record is one survey participant, keyed on **`SEQN`** (unique NHANES
respondent ID). Component files are pulled per cycle and left-joined onto the
demographics spine by `SEQN`.

---

## 1. Cycles included

| Label | File | Exam / dietary weight vars | Span (yrs) | hs-CRP | BP method |
|-------|------|----------------------------|-----------|--------|-----------|
| 2015–2016 | `_I` | `WTMEC2YR` / `WTDRD1` | 2 | Yes | Auscultatory (mercury) |
| 2017–March 2020 (pre-pandemic) | `P_` | `WTMECPRP` / `WTDRD1PP` | 3.2 | Yes | Oscillometric |
| 2021–2023 (Aug–Aug) | `_L` | `WTMEC2YR` / `WTDRD1` | 2 | Yes | Oscillometric |

The pre-pandemic file (`P_`) is used instead of a standalone 2017–2018 (`_J`)
so the 2019–March 2020 sample is not discarded — that data exists **only** inside
`P_`. Because `P_` already contains the 2017–2018 respondents, do **not** also add
`_J` (or any overlapping 2017–2018 file) to this set. Latest released cycle is
`_L` (August 2021–August 2023); there is no `_M` yet.

**Unavoidable collection gap.** NHANES suspended field operations from March 2020
until August 2021, so essentially nothing was collected ~April 2020–July 2021.
Using `P_` recovers 2019–March 2020, but this ~17-month hole is intrinsic to
NHANES and is not closed by any file choice. Relevant if treating the pool as a
time series.

---

## 2. Source variables by component file

### Demographics — `DEMO` / `P_DEMO`

| Variable | Description | Units / coding |
|----------|-------------|----------------|
| `SEQN` | Respondent sequence number (join key) | integer |
| `RIDAGEYR` | Age at screening | years (top-coded at 80) |
| `RIAGENDR` | Sex | 1 = Male, 2 = Female |
| `RIDRETH3` | Race / Hispanic origin (incl. NH Asian) | 1 = Mexican American, 2 = Other Hispanic, 3 = NH White, 4 = NH Black, 6 = NH Asian, 7 = Other/Multi |
| `WTMEC2YR` / `WTMECPRP` | 2-year MEC exam weight / pre-pandemic MEC weight | numeric → canonicalized to `WTMEC` |
| `SDMVPSU` | Masked variance pseudo-PSU | integer |
| `SDMVSTRA` | Masked variance pseudo-stratum | integer |

### Dietary, Day 1 total nutrients — `DR1TOT` / `P_DR1TOT`

Codes below are corrected from the paper's list (see §5).

| Variable | Description | Units |
|----------|-------------|-------|
| `DR1TPROT` | Protein | g |
| `DR1TCARB` | Carbohydrate | g |
| `DR1TSUGR` | Total sugars | g |
| `DR1TFIBE` | Dietary fiber | g |
| `DR1TSFAT` | Saturated fatty acids | g |
| `DR1TMFAT` | Monounsaturated fatty acids | g |
| `DR1TPFAT` | Polyunsaturated fatty acids | g |
| `DR1TCHOL` | Cholesterol (dietary) | mg |
| `DR1TBCAR` | Beta-carotene | mcg |
| `DR1TCRYP` | Beta-cryptoxanthin | mcg |
| `DR1TLYCO` | Lycopene | mcg |
| `DR1TVB1` | Thiamin (vitamin B1) | mg |
| `DR1TVB2` | Riboflavin (vitamin B2) | mg |
| `DR1TNIAC` | Niacin | mg |
| `DR1TVB6` | Vitamin B6 | mg |
| `DR1TFOLA` | Total folate | mcg |
| `DR1TFF` | Food folate | mcg |
| `DR1TIRON` | Iron | mg |
| `DR1TCHL` | Total choline ⚠️ absent before 2005–2006 | mg |
| `DR1TVB12` | Vitamin B12 | mcg |
| `DR1TVC` | Vitamin C | mg |
| `DR1TVD` | Vitamin D (D2 + D3) | mcg |
| `DR1TATOC` | Vitamin E as alpha-tocopherol | mg |
| `DR1TVK` | Vitamin K | mcg |
| `DR1TCALC` | Calcium | mg |
| `DR1TPHOS` | Phosphorus | mg |
| `DR1TMAGN` | Magnesium | mg |
| `DR1TZINC` | Zinc | mg |
| `DR1TCOPP` | Copper | mg |
| `DR1TSODI` | Sodium | mg |
| `DR1TPOTA` | Potassium | mg |
| `DR1TSELE` | Selenium | mcg |
| `DR1TMOIS` | Moisture | g |
| `WTDRD1` / `WTDRD1PP` | Day-1 dietary weight / pre-pandemic day-1 weight | numeric → canonicalized to `WTDR1` |

### Body measures — `BMX` / `P_BMX`

| Variable | Description | Units |
|----------|-------------|-------|
| `BMXBMI` | Body Mass Index | kg/m² |
| `BMXWAIST` | Waist circumference | cm |

### Blood pressure — `BPX` (auscultatory) / `BPXO` (oscillometric)

| Variable | Description | Units | Cycles |
|----------|-------------|-------|--------|
| `BPXSY1` | Systolic, 1st reading (auscultatory / mercury) | mmHg | ≤ 2017–2018 (here: `_I`) |
| `BPXDI1` | Diastolic, 1st reading (auscultatory / mercury) | mmHg | ≤ 2017–2018 (here: `_I`) |
| `BPXOSY1` | Systolic, 1st oscillometric reading | mmHg | pre-pandemic, `_L` |
| `BPXODI1` | Diastolic, 1st oscillometric reading | mmHg | pre-pandemic, `_L` |

Collapsed into canonical `SBP1` / `DBP1` in the output; `bp_method` records which device produced them.

### Total cholesterol — `TCHOL` / `P_TCHOL`

| Variable | Description | Units |
|----------|-------------|-------|
| `LBXTC` | Total cholesterol (serum) | mg/dL |

### High-sensitivity CRP — `HSCRP` / `P_HSCRP`

| Variable | Description | Units |
|----------|-------------|-------|
| `LBXHSCRP` | High-sensitivity C-reactive protein | **mg/L** |

> Replaces the paper's `LBXCRP`. `LBXHSCRP` begins in 2015–2016. Pre-2015 cycles
> carry only `LBXCRP` (mg/dL, ×10 → mg/L, different assay); 2011–2014 has no CRP.

### Medical conditions / outcome — `MCQ` / `P_MCQ`

| Variable | Description | Coding |
|----------|-------------|--------|
| `MCQ160B` | Ever told had congestive heart failure | 1 = Yes, 2 = No |
| `MCQ160C` | Ever told had coronary heart disease | 1 = Yes, 2 = No |
| `MCQ160D` | Ever told had angina / angina pectoris | 1 = Yes, 2 = No |
| `MCQ160E` | Ever told had heart attack (MI) | 1 = Yes, 2 = No |
| `MCQ160F` | Ever told had a stroke | 1 = Yes, 2 = No |

---

## 3. Derived / output columns

| Column | Definition |
|--------|------------|
| `SBP1` | First systolic reading (`BPXOSY1` if oscillometric, else `BPXSY1`) |
| `DBP1` | First diastolic reading (`BPXODI1` if oscillometric, else `BPXDI1`) |
| `bp_method` | `"oscillometric"` or `"auscultatory"` — device behind `SBP1`/`DBP1` |
| `cycle` | Cycle label (e.g., `"2017-2020"`) |
| `cyc_years` | Time span the cycle represents (2 or 3.2) — used for pooled weights |
| `WTMEC` | MEC exam weight, canonicalized (`WTMEC2YR` or `WTMECPRP`) |
| `WTDR1` | Day-1 dietary weight, canonicalized (`WTDRD1` or `WTDRD1PP`) |
| `WTMEC_pool` | Pooled MEC weight (see §4) |
| `WTDR1_pool` | Pooled day-1 dietary weight (see §4) |
| `cvd` | Composite outcome: `1` if any `MCQ160B–F` = Yes; `0` if all answered No; `NA` if all five missing |

---

## 4. Survey weights & pooling

**Which weight.** Use `WTDR1`-based weights for any model that includes dietary
(`DR1T*`) predictors — the 24-hour recall is a subsample with its own weight. Use
`WTMEC`-based weights for exam/lab-only models. `SDMVPSU` / `SDMVSTRA` are
required for design-based standard errors (`nest = TRUE`).

**Pooling across cycles of unequal length (NCHS rule).** The pre-pandemic file
represents 3.2 years, not 2, so a simple `1/k` is wrong. Each cycle's weight is
scaled by its share of the total pooled span:

```
pooled weight = raw weight × (cycle years / total years)
```

For this set total = 2 + 3.2 + 2 = **7.2 years**, giving multipliers of
`2/7.2` for 2015–2016 and 2021–2023 and `3.2/7.2` for the pre-pandemic file.
This formula collapses to `1/k` when every cycle is a standard 2-year release
(e.g., if the pre-pandemic row is dropped for a paper-exact `P_ + _L`… or an
all-2-year set).

Design object, dietary-inclusive model:

```r
svydesign(ids = ~SDMVPSU, strata = ~SDMVSTRA,
          weights = ~WTDR1_pool, nest = TRUE, data = dat_all)
```

Conservative option if you're unsure whether stratum codes repeat across cycles:
use `interaction(cycle, SDMVSTRA)` as the stratum.

### Interpreting the weight magnitudes (why the numbers look huge)

A NHANES weight is **not** a count of surveyed people — it is an estimate of how
many people in the U.S. population that one respondent represents. So values in
the tens of thousands are expected, not errors. A typical MEC weight is roughly
20,000 (that respondent stands in for ~20,000 Americans); oversampled or
rare-profile respondents can represent several hundred thousand.

**The population sum is the sanity check.** Within a single cycle, `WTMEC2YR` sums
to the entire U.S. civilian non-institutionalized population (~320 million). Two
consequences for pooled data:

- The **raw** weight column, stacked across *k* cycles, sums to roughly *k* ×
  population (e.g., ~960 million across 3 cycles ≈ 3× the country). This is why
  raw per-cycle weights must never be used directly on a pooled file — they
  triple-count the population.
- The **pooled** weight column (`WTMEC_pool` / `WTDR1_pool`) sums back to ~1 ×
  population (~320 million). Getting a pooled sum near the true U.S. population is
  the confirmation the scaling is right; use these columns for estimation.

**Zeros and a smaller dietary N are expected, not bugs.** Interviewed-but-not-
examined participants get `WTMEC = 0`; participants without a valid Day-1 recall
get `WTDR1 = 0`, and the dietary recall is a subsample so `WTDR1` is populated for
fewer rows than `WTMEC`. A zero weight simply means "represents nobody in this
particular analysis."

**Feeding weights to models.** For design-based estimation (`survey` package),
pass the pooled weights **as-is** — it expects population-scaled weights. For an
ML routine where the large magnitudes are numerically awkward, you may rescale to
mean 1 (`w / mean(w)`); this preserves every respondent's *relative* weight and
does not change the fit. Do **not** rescale weights passed to `svydesign`.

---

## 5. Backward-extension floors (per variable)

How far back each variable can go if the cycle set is extended earlier:

| Variable | Earliest cycle | Note |
|----------|----------------|------|
| hs-CRP (`LBXHSCRP`) | **2015–2016** | Strictest floor. Older cycles have only `LBXCRP` (mg/dL, ≤2009–2010, non-hs assay); no CRP 2011–2014. |
| Total choline (`DR1TCHL`) | **2005–2006** | Absent in 2003–2004 and earlier. |
| Oscillometric BP (`BPXO*`) | 2017–2018 | Auscultatory `BPX*` exists earlier; crossing the boundary mixes methods. |
| Everything else | 1999–2000 | Macros, other vitamins/minerals, `BMX`, `LBXTC`, `MCQ160*`. |

As long as hs-CRP is retained, its 2015–2016 floor binds first, so choline's 2005
limit never matters. Choline only becomes the constraint if hs-CRP is dropped to
chase a longer series — in which case the clean window with both `LBXCRP` and
`DR1TCHL` is 2005–2006 → 2009–2010.

---

## 6. Corrections applied to the paper's variable list

| Paper's code / label | Issue | Used here |
|----------------------|-------|-----------|
| `LBXCRP` — "CRP (mg/dL)" | Not collected in these cycles | `LBXHSCRP` (mg/L), `HSCRP` file |
| `BPXSY1` / `BPXDI1` | Absent from pre-pandemic & 2021–23 files | `BPXOSY1` / `BPXODI1` (`BPXO`) where applicable |
| `DR1TTHEO` — "Thiamin" | Resolves, but is **theobromine** | `DR1TVB1` (thiamin) |
| `DR1TRBF` — "Riboflavin" | Non-standard code (does not resolve) | `DR1TVB2` (riboflavin) |
| `DR1TCHO` — "Choline" | Non-standard code (does not resolve) | `DR1TCHL` (total choline) |
| `DR1TLYCO` — "Lycopene / Lutein+Zeax." | One code = lycopene only | `DR1TLYCO`; add `DR1TLZ` for lutein+zeaxanthin |

The extract script prints a per-cycle `missing:` report, so any code that fails to
resolve is surfaced at run time rather than silently dropped.

---

*Source: NHANES public data files, wwwn.cdc.gov. Component files linked on `SEQN`.
Weights and design variables per NHANES Analytic Guidelines; pre-pandemic pooling
per NCHS 2017–March 2020 analytic guidance.*
