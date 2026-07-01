# Vasi Bounded Mixed Regression Model
Victor Eduardo Lachos Olivares <sup>1</sup> and Jorge Luis Bazán Guzmán<sup>2</sup>Catalina B. García-García<sup>3</sup>

<sup>1</sup>Department of Statistics at the Federal University of São Carlos (UFSCar) and the Department of Applied Mathematics and 
Statistics at the Institute of Mathematical and Computer Sciences of the University of São Paulo (ICMC-USP), São Carlos, Brazil.
<sup>2</sup>Department of Applied Mathematics and Statistics, University of São Paulo, São Carlos, Brazil.
<sup>3</sup>Department of Quantitative Methods for Economics and Business, University of Granada, Spain.

Corresponding Authors: Eduardo Lachos Olivares: velo28@usp.br 

This material serves as a supplementary resource to the paper "Vasi Bounded Mixed Regression Model". The Vasi model is particularly well-suited for situations in which the variable of interest is continuous and is bounded within the interval (0,1), and in which explanatory variables are incorporated through a regression structure through Bayesian framework.

## Previous installations

- Running the scripts requires the STAN software, which is installed via the RStan package. Installation instructions can be found in:
Guo, J., Gabry, J., Goodrich, B., & Weber, S. (2020). Package ‘rstan’. URL https://cran. r―project.
A supplementary guide is available at: [https://www.jstatsoft.org/index.php/jss/article/view/v012i03/33]) and [https://mc-stan.org/docs/2_21/stan-users-guide-2_21.pdf

## File description:

The project includes the following files and folders:
- main.vasi.R: This script contains the code to read the data from the file datasets.
- main.vasi.mixed.R: This script contains the code to read the data considering random effects. 
   It utilizes two primary datasets:
*data_poverty_mg.csv
*datapov_peru.csv

- datasets:  
This folder contains poverty data from Mato Grosso (MG), Brazil, for 2010, including two variables:

The proportion of out-of-school children aged 6–14

The corresponding Human Development Index (HDI) by municipality.

It also includes poverty data from regions of Peru, covering:

Extreme poverty levels

The Human Development Index (HDI) by municipality.

-codes: it contains the functions.R for reading the dataset in main.vasi.R and main.vasi.mixed.R, which can be in format .csv, .txt, .xls, and .xlsx.
- models: This folder contains the codes in stan, which includes for Beta, Simplex and Vasi-Normal as well as the codes
 for Mixed regression Vasi-Normal model introducing random effects in mean and dispersion parameters.

## Instructions for Running R and RStan Codes

Open main.vasi.R  or main.vasi.mixed.R in R and specify the dataset to be used. The dataset must follow the format defined in the datasets folder. Once configured, run the script considering the models below respectively.

```r
model_files <- list(
  vasi = "models/stan_vasi.stan",#stan_vasi_mixed_loc #stan_vasi_mixed_loc_dis
  beta = "models/stan_beta.stan",
  simplex = "models/stan_simplex.stan"
)
```
```r
model_files <- list(
  vasi = "models/stan_vasi_mixed_loc.stan"#stan_vasi_mixed_loc_dis
)
```

The default Stan model settings are preconfigured as: 

iter = 5000
warmup  = 2500
chains = 1
Priors for the parameters in stan.


These settings can be modified if needed. The model also computes the criteria WAIC and LOO from loo package, 
, as well as EAIC and EBIC. All results, including the estimates obtained from the selected model, will be saved in the results folder.

```r
# Save criteria to CSV for this model
    criteria_df <- data.frame(
      model = model_name,
      waic = ifelse(is.null(model_criteria$waic_value), NA, model_criteria$waic_value),
      waic_se = ifelse(is.null(model_criteria$waic_se), NA, model_criteria$waic_se),
      loo = ifelse(is.null(model_criteria$loo_value), NA, model_criteria$loo_value),
      loo_se = ifelse(is.null(model_criteria$loo_se), NA, model_criteria$loo_se),
      eaic = model_criteria$eaic,
      ebic = model_criteria$ebic
    )
    
    criteria_path <- file.path(results_dir, paste0("criteria_", model_name, ".csv"))
    write.csv(criteria_df, criteria_path, row.names = FALSE)
    cat("Criteria saved:", criteria_path, "\n")
```
   
