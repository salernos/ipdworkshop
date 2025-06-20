#===============================================================================
# NHANES_DATA.R
#===============================================================================

#=== SETUP =====================================================================

#--- LOAD NECESSARY PACKAGES ---------------------------------------------------

library(nhanesA)
library(tidyverse)

#=== DOWNLOAD DATA =============================================================

#--- 2017-2018 WAVE (J) --------------------------------------------------------

#-- Download 2017-2018 Datasets

# https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/default.aspx?BeginYear=2017

DEMO_J <- nhanes("DEMO_J")  # Demographics
BMX_J  <- nhanes("BMX_J")   # Body Measures
DXX_J  <- nhanes("DXX_J")   # Dual-Energy X-Ray Absorptiometry - Whole Body
SMQ_J  <- nhanes("SMQ_J")   # Smoking - Cigarette Use

#-- Combine 2017-2018 Datasets

DAT_J <- DEMO_J |>

  #- Combine Data by Participant ID (SEQN)

  full_join(BMX_J, "SEQN") |>
  full_join(DXX_J, "SEQN") |>
  full_join(SMQ_J, "SEQN") |>

  #- Select Variables of Interest

  select(

    SEQN,        # Respondent Sequence Number
    SDDSRVYR,    # Data Release Cycle
    WTMEC2YR,    # Full Sample 2-Year MEC Exam Weight
    RIDAGEYR,    # Age in Years at Screening
    RIAGENDR,    # Gender
    RIDRETH3,    # Race/Hispanic Origin w/ NH Asian
    DMDEDUC2,    # Education Level - Adults 20+
    BMXBMI,      # Body Mass Index (kg/m^2)
    BMXWAIST,    # Waist Circumference (cm)
    DXDTOPF,     # Total Percent Fat
    SMQ040,      # Do you now smoke cigarettes?
    SMQ621,      # Cigarettes smoked in entire life
    SMQ050Q) |>  # How long since quit smoking cigarettes

  #- Filter Out Participants Missing BMI, WC or DXA

  filter(!is.na(BMXBMI), !is.na(BMXWAIST), !is.na(DXDTOPF))

#--- AUGUST 2021 - AUGUST 2023 WAVE (L) ----------------------------------------

#-- Download Data

# https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/default.aspx?Cycle=2021-2023

DEMO_L <- nhanes("DEMO_L")  # Demographics Data
BMX_L  <- nhanes("BMX_L")   # Body Measures
SMQ_L  <- nhanes("SMQ_L")   # Smoking - Cigarette Use

#-- Combine Data by Participant ID (SEQN)

DAT_L <- DEMO_L |>

  #- Combine Data by Participant ID (SEQN)

  full_join(BMX_L, "SEQN") |>
  full_join(SMQ_L, "SEQN") |>

  #- Select Variables of Interest

  select(

    SEQN,      # Respondent Sequence Number
    SDDSRVYR,  # Data Release Cycle
    WTMEC2YR,  # Full Sample 2-Year MEC Exam Weight
    RIDAGEYR,  # Age in Years at Screening
    RIAGENDR,  # Gender
    RIDRETH3,  # Race/Hispanic Origin w/ NH Asian
    DMDEDUC2,  # Education Level - Adults 20+
    BMXBMI,    # Body Mass Index (kg/m^2)
    BMXWAIST,  # Waist Circumference (cm)
    SMQ040,    # Do you now smoke cigarettes?
    SMQ621,    # Cigarettes smoked in entire life
    SMQ050Q    # How long since quit smoking cigarettes
  ) |>

  #- Filter Out Participants Missing BMI or WC

  filter(!is.na(BMXBMI), !is.na(BMXWAIST))

#=== PRE-PROCESS DATA ==========================================================

#--- Combine Data

NHANES <- bind_rows(DAT_J, DAT_L) |>

  mutate(

    #-- Construct Obesity Variables Based on BMI, WC, DXA

    obese_bmi = if_else(BMXBMI >= 30, 1, 0, NA_real_),  # BMI Score of 30+

    obese_wc  = case_when(

      RIAGENDR == "Male"   & BMXWAIST >= 102 ~ 1,       # 102cm for Males

      RIAGENDR == "Male"   & BMXWAIST <  102 ~ 0,

      RIAGENDR == "Female" & BMXWAIST >=  88 ~ 1,       #  88cm for Females

      RIAGENDR == "Female" & BMXWAIST <   88 ~ 0,

      .default = NA_real_),

    obese_dxa = case_when(

      RIAGENDR == "Male"   & DXDTOPF >= 30 ~ 1,         # 30% for Males

      RIAGENDR == "Male"   & DXDTOPF <  30 ~ 0,

      RIAGENDR == "Female" & DXDTOPF >= 42 ~ 1,         # 42% for Females

      RIAGENDR == "Female" & DXDTOPF <  42 ~ 0,

      .default = NA_real_),

    #-- Refactor Covariate Data

    #- Cohort

    Cohort = factor(SDDSRVYR,

      levels = c("NHANES 2017-2018 public release",
                 "NHANES August 2021-August 2023 public release"),

      labels = c("2017-2018", "2021-2023")),

    #- Age

    Age = case_when(

      RIDAGEYR < 20 ~ "Under 20",

      RIDAGEYR < 40 ~ "20-39",

      RIDAGEYR < 60 ~ "40-59",

      RIDAGEYR >= 60 ~ "60+",

      .default = NA_character_) |>

      factor(levels = c("Under 20", "20-39", "40-59", "60+")),

    #- Sex

    Sex = RIAGENDR,

    #- Race

    Race = RIDRETH3 |>

      fct_collapse(Hispanic = c("Mexican American", "Other Hispanic")) |>

      fct_relevel("Non-Hispanic White"),

    #- Smoking Status

    Smoking = case_when(

      SMQ040  %in% seq_len(2)   ~ "Current Smoker",

      SMQ050Q %in% seq_len(193) ~ "Former Smoker",

      SMQ621  %in% seq_len(2)   ~ "Never Smoker",

      .default = NA_character_) |>

      factor(levels = c("Never Smoker", "Former Smoker", "Current Smoker")),

    #- Education Level

    Education = DMDEDUC2 |>

      fct_na_value_to_level("NA") |>

      fct_collapse(

        `Less than high school` = c("Less than 9th grade",

          "9-11th grade (Includes 12th grade with no diploma)"),

        `Refused/Unknown` = c("Refused", "Don't Know", "Don't know", "NA")) |>

      fct_relevel("Less than high school",

        "High school graduate/GED or equivalent", "Some college or AA degree",

        "College graduate or above", "Refused/Unknown"),

    #-- 4-Year Survey Weights

    WTMEC4YR = WTMEC2YR / 2) |>

  select(SEQN, Cohort, Age, Sex, Race, Smoking, Education,

    BMXBMI, BMXWAIST, DXDTOPF, WTMEC4YR)

# save output as .rds file
save(NHANES, file = "./vignettes/data/NHANES.RData")
