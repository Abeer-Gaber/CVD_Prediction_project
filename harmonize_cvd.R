# 02_harmonize_cvd.R ----------------------------------------------------------
# Build the prevalent-CVD composite label from MCQ160 and a risk-factor-only
# feature set. Assumes data/raw_by_cycle.rds exists from the shared
# cvd-pipeline/R/01_download.R step.

library(dplyr)
library(purrr)

raw <- readRDS("data/raw_by_cycle.rds")

harmonize_cycle <- function(fr) {
  reduce_join <- function(...) reduce(list(...), \(a, b) left_join(a, b, by = "SEQN"))
  
  demo <- fr$demo %>% transmute(
    SEQN, cycle = fr$cycle, age = RIDAGEYR,
    sex = ifelse(RIAGENDR == 1, "M", "F"),
    wt_mec = WTMEC2YR, SDMVSTRA, SDMVPSU, income = INDFMPIR,
    educ = if ("DMDEDUC2" %in% names(fr$demo)) DMDEDUC2 else NA_real_,
    race = if ("RIDRETH3" %in% names(fr$demo)) RIDRETH3 else RIDRETH1)
  
  tchol <- fr$tchol %>% transmute(SEQN, tc = LBXTC)
  hdl   <- fr$hdl   %>% transmute(SEQN, hdl = LBDHDD)
  bpq   <- fr$bpq   %>% transmute(SEQN, bp_treated = as.integer(BPQ050A == 1 & !is.na(BPQ050A)))
  smq   <- fr$smq   %>% transmute(SEQN, smoker = as.integer(SMQ020 == 1 & SMQ040 %in% c(1, 2)))
  diq   <- fr$diq   %>% transmute(SEQN, diabetic = as.integer(DIQ010 == 1))
  bmx   <- fr$bmx   %>% transmute(SEQN, bmi = BMXBMI,
                                  waist = if ("BMXWAIST" %in% names(fr$bmx)) BMXWAIST else NA_real_)
  
  # LABEL: any reported CVD condition. Lives apart from the feature set.
  has <- function(v) if (v %in% names(fr$mcq)) fr$mcq[[v]] == 1 else FALSE
  mcq <- fr$mcq %>% transmute(SEQN,
                              had_cvd = as.integer(has("MCQ160B") | has("MCQ160C") |
                                                     has("MCQ160D") | has("MCQ160E") | has("MCQ160F")))
  
  # SBP harmonized across the device change (carry bp_method as a feature).
  sys_cols <- grep("^BPX(O)?SY[1-4]$", names(fr$bp), value = TRUE)
  bp <- fr$bpx %>%  mutate(
    sbp = rowMeans(
      select(., all_of(sys_cols)),
      na.rm = TRUE
    )
  ) %>%
    transmute(SEQN, sbp) %>% 
  reduce_join(demo, tchol, hdl, bpq, smq, diq, bmx, bp) %>%
    left_join(mcq, by = "SEQN") %>%
    mutate(bp_method = fr$bp_method,
           across(c(bp_treated, smoker, diabetic), ~ coalesce(.x, 0L)))
}

pooled <- map(raw, harmonize_cycle) %>% bind_rows()
pooled<-pooled %>% filter(!is.na(had_cvd))
saveRDS(pooled, "data/pooled.rds")
message("Saved data/pooled.rds (", nrow(pooled), " rows); ",
        "prevalent CVD = ", sum(pooled$had_cvd, na.rm = TRUE))

library(writexl)

write_xlsx(
  pooled,
  "data/pooled.xlsx"
)
