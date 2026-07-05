# =====================================================================
# NHANES multi-cycle extract — CVD ML replication (PMC12591444)
# Cycle set: 2015-2016, 2017-March 2020 (pre-pandemic), 2021-2023
# Pre-pandemic file kept to avoid dropping the 2019-March 2020 sample.
# =====================================================================

# install.packages(c("nhanesA", "dplyr"))
library(nhanesA)
library(dplyr)

# ---------------------------------------------------------------------
# 1. Cycles.  pre = TRUE -> "P_" prefix + special 3.2-year weights.
#    years   = span each cycle represents (drives the pooled weight).
# ---------------------------------------------------------------------
cycles <- data.frame(
  label = c("2015-2016", "2017-2020", "2021-2023"),
  sfx   = c("I",         "",          "L"),
  pre   = c(FALSE,       TRUE,        FALSE),
  years = c(2,           3.2,         2),
  stringsAsFactors = FALSE
)
# To mirror the paper exactly (drop 2015-2016), delete the first row.

# ---------------------------------------------------------------------
# 2. Non-weight variables per component file.
#    Weight variables are resolved per cycle in the loop (their names
#    differ in the pre-pandemic file). Dietary codes below are corrected
#    from the paper's list:
#      DR1TTHEO (theobromine) -> DR1TVB1 (thiamin)
#      DR1TRBF  (not a code)  -> DR1TVB2 (riboflavin)
#      DR1TCHO  (not a code)  -> DR1TCHL (total choline; absent pre-2005)
# ---------------------------------------------------------------------
diet_vars <- c("DR1TPROT","DR1TCARB","DR1TSUGR","DR1TFIBE","DR1TSFAT",
               "DR1TMFAT","DR1TPFAT","DR1TCHOL","DR1TBCAR","DR1TCRYP",
               "DR1TLYCO","DR1TVB1","DR1TVB2","DR1TNIAC","DR1TVB6",
               "DR1TFOLA","DR1TFF","DR1TIRON","DR1TCHL","DR1TVB12",
               "DR1TVC","DR1TVD","DR1TATOC","DR1TVK","DR1TCALC",
               "DR1TPHOS","DR1TMAGN","DR1TZINC","DR1TCOPP","DR1TSODI",
               "DR1TPOTA","DR1TSELE","DR1TMOIS")
demo_vars  <- c("RIDAGEYR","RIAGENDR","RIDRETH3","SDMVPSU","SDMVSTRA")
bmx_vars   <- c("BMXBMI","BMXWAIST")
tchol_vars <- c("LBXTC")
crp_vars   <- c("LBXHSCRP")
mcq_vars   <- c("MCQ160B","MCQ160C","MCQ160D","MCQ160E","MCQ160F")

# ---------------------------------------------------------------------
# 3. Pull + merge per cycle
# ---------------------------------------------------------------------
all_cycles <- list()

for (i in seq_len(nrow(cycles))) {
  lab <- cycles$label[i]; sfx <- cycles$sfx[i]
  pre <- cycles$pre[i];   yr  <- cycles$years[i]
  message("\n=== ", lab, " ===")
  
  # per-cycle weight variable names (pre-pandemic uses the "PP"/"PRP" set)
  mec_wt  <- if (pre) "WTMECPRP" else "WTMEC2YR"
  diet_wt <- if (pre) "WTDRD1PP" else "WTDRD1"
  
  components <- list(
    DEMO   = c(demo_vars, mec_wt),
    DR1TOT = c(diet_vars, diet_wt),
    BMX    = bmx_vars,
    TCHOL  = tchol_vars,
    HSCRP  = crp_vars,
    MCQ    = mcq_vars
  )
  
  merged <- NULL
  for (base in names(components)) {
    tbl <- if (pre) paste0("P_", base) else paste0(base, "_", sfx)
    dat <- nhanes(tbl, translated = FALSE)
    
    want    <- components[[base]]
    present <- intersect(want, names(dat))
    missing <- setdiff(want, names(dat))
    if (length(missing))
      message("  ", tbl, " missing: ", paste(missing, collapse = ", "))
    
    dat    <- dat[, c("SEQN", present)]
    merged <- if (is.null(merged)) dat else left_join(merged, dat, by = "SEQN")
  }
  
  # blood pressure: oscillometric for pre-pandemic & _L, auscultatory for _I
  if (pre || sfx == "L") {
    bp_tbl    <- if (pre) "P_BPXO" else paste0("BPXO_", sfx)
    bp        <- nhanes(bp_tbl, translated = FALSE)[, c("SEQN","BPXOSY1","BPXODI1")]
    bp_method <- "oscillometric"
  } else {
    bp_tbl    <- paste0("BPX_", sfx)
    bp        <- nhanes(bp_tbl, translated = FALSE)[, c("SEQN","BPXSY1","BPXDI1")]
    bp_method <- "auscultatory"
  }
  names(bp) <- c("SEQN", "SBP1", "DBP1")
  merged    <- left_join(merged, bp, by = "SEQN")
  
  # canonical weight names (so the columns line up across cycles)
  names(merged)[names(merged) == mec_wt]  <- "WTMEC"
  names(merged)[names(merged) == diet_wt] <- "WTDR1"
  
  merged$cycle     <- lab
  merged$bp_method <- bp_method
  merged$cyc_years <- yr
  all_cycles[[lab]] <- merged
}

# ---------------------------------------------------------------------
# 4. Stack + composite CVD outcome
# ---------------------------------------------------------------------
dat_all <- bind_rows(all_cycles)

mcq_mat     <- as.matrix(dat_all[mcq_vars])
yes_any     <- rowSums(mcq_mat == 1, na.rm = TRUE) > 0
all_na      <- rowSums(!is.na(mcq_mat)) == 0
dat_all$cvd <- ifelse(all_na, NA_integer_, as.integer(yes_any))

# ---------------------------------------------------------------------
# 5. Pooled survey weights (NCHS time-span rule)
#    pooled = raw * (cycle years / total pooled years)
#    -> collapses to 1/k when every cycle is 2 years.
# ---------------------------------------------------------------------
total_years        <- sum(cycles$years)              # 7.2 for this set
dat_all$WTMEC_pool <- dat_all$WTMEC * (dat_all$cyc_years / total_years)
dat_all$WTDR1_pool <- dat_all$WTDR1 * (dat_all$cyc_years / total_years)

saveRDS(dat_all, "nhanes_cvd_extract.rds")
message("\nRows: ", nrow(dat_all),
        " | Cases: ", sum(dat_all$cvd == 1, na.rm = TRUE),
        " | Pooled span: ", total_years, " yrs")

library(writexl)
write_xlsx(nhanes_cvd_extract,"nhanes_cvd_extract.xlsx")
