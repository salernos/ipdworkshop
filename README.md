# Introduction and Motivation

Artificial intelligence and machine learning (AI/ML) have become essential tools in biomedical research, enabling large-scale analyses across diverse domains such as genomics, structural biology, and electronic health records-based research. Increasingly, researchers rely on model-generated predictions, rather than directly measured variables, as inputs for downstream statistical analyses. For example, predicted gene expression values or polygenic risk scores are often used in place of experimental assays, allowing researchers to expand cohort sizes and explore hypotheses when traditional data collection is infeasible, costly, or time-consuming.

While this practice of "using predictions as data" holds promise for accelerating scientific discovery, it presents significant challenges for statistical inference. When predicted values are used in place of true variables, the resulting estimates of association can be biased and misleading if uncertainty in the prediction step is not properly accounted for. 

In this workshop, we explore the consequences of inference on predicted data across several biomedical applications.  Drawing from classical approaches to measurement error and recent developments in bias correction, we will present a suite of prediction-based inference methods that adjust for prediction-related uncertainty and improve inference validity and efficiency. We will also introduce {ipd}, a user-friendly Bioconductor R package that implements several of these correction methods through a unified interface. The package supports modular integration into existing workflows and includes tidy methods for model inspection and diagnostics.





################################################################################




In many modern data science applications, it is common to encounter settings 
where measuring a particular outcome, $Y$, is expensive or time-consuming, 
whereas predictions, $\hat{Y} = f(X)$, from a machine learning model are 
readily available on largedatasets. The `ipd` package provides a suite of 
methods to perform valid  statistical inference on when some outcomes are 
observed (labeled) and others are only predicted.

In this workshop, you will learn:

* The theoretical foundation behind prediction-powered inference (PPI) and its extensions.
* How to use **ipd** functions to simulate data, fit models, and extract inference results.
* Practical exercises to compare naive estimators with IPD methods.

By the end, you should be able to design analyses that leverage large unlabeled datasets while maintaining correct uncertainty quantification.

## The Augmented Data Scheme

Consider three sets of observations:

* **Training set**: ${(X_i, Y_i)}*{i=1}^{n*\text{train}}$, used to fit a predictive model $f(\cdot)$.
* **Labeled set**: ${(X_i, Y_i)}*{i=1}^{n*\ell}$, smaller sample with true outcomes.
* **Unlabeled set**: ${X_i}*{i=n*\text{train}+n_\ell+1}^{n_\text{train}+n_\ell+n_u}$, only features available.

After fitting $f$ on the training set, we apply it to the labeled and unlabeled sets to obtain predictions $f_i = f(X_i)$. We then construct an **augmented dataset**:

```plaintext
+---------------+      +---------------+      +----------------+
| Training (T)  | ---> | Labeled (L)   | ---> | Unlabeled (U)  |
| (X, Y)        |      | (X, Y, f)     |      | (X, f)         |
+---------------+      +---------------+      +----------------+
```

We treat $f_i$ in the unlabeled set as surrogate outcomes and combine them with observed $Y_i$ in the labeled set to estimate regression parameters $\beta$.

## Key Formulas

### Naive Estimator

Using only the unlabeled predictions, the naive OLS estimator solves

$$
\hat\beta_{\text{naive}} = \arg\min_\beta \sum_{i\in U} \bigl(f_i - X_i^T\beta\bigr)^2.
$$



# This Workshop

Welcome! This workshop provides a brief introduction to performing valid statistical inference when your outcome has been partially imputed by a machine learning model. The central package is [**ipd**](https://bioconductor.org/packages/ipd/), which implements several recent methods for conducting inference with predicted data (IPD).

> **Prerequisites**  
> 1. R (≥ 4.1) and Bioconductor installed  
> 2. The `ipd` package:  
>    ```r
>    if (!requireNamespace("BiocManager", quietly = TRUE))
>        install.packages("BiocManager")
>    BiocManager::install("ipd")
>    ```
> 3. Supporting packages:
>    ```r
>    install.packages(c("tidyverse", "patchwork", "NHANES", "rashomonquartet", "ranger", "mgcv", "pROC", "ALL"))
>    BiocManager::install(c("BiocStyle", "Biobase", "BiocGenerics"))
>    ```

---

## Workshop Structure

There are four hands‐on tutorials (R Markdown vignettes). Each vignette loads or simulates data, trains a prediction model, applies `ipd::ipd()`, and includes exercises:

1. [Chapter 1: Simulated Data](vignettes/01-simulated-data.html)  
   - Fully synthetic linear‐regression example  
   - Compare naïve, classical, and PPI/PPI++/PostPI/PSPA methods  
   - Residual diagnostics and bootstrap coverage

2. [Chapter 2: Rashomon Quartet](vignettes/02-rashomon-quartet.html)  
   - Illustrate how four datasets with identical summary statistics can behave very differently  
   - Show why naïve regression on predictions can fail under nonlinearity or outliers  
   - Compare IPD corrections (PPI, PPI++, PSPA) across R1–R4 scenarios

3. [Chapter 3: NHANES Body Fat vs BMI](vignettes/03-nhanes-bodyfat.html)  
   - Real‐world data from NHANES (DXA percent body fat vs BMI)  
   - Fit a linear (or nonlinear) prediction model on labeled participants  
   - Use IPD to estimate the effect of Age on true percent body fat (correcting for bias)

4. [Chapter 4: Genetic Data (Bioconductor `ALL`)](vignettes/04-genetic-data.html)  
   - A binary IPD example using leucemia microarray data (`ALL` package)  
   - Fit a logistic model (CD19‐based) to predict BCR/ABL labels  
   - Apply IPD to estimate the log‐odds effect of CD38 expression on true BCR/ABL status

---

## How to Build & View Locally

1. Clone or download this repository:

```bash
git clone https://github.com/salernos/ipdworkshop.git
cd ipdworkshop
```

