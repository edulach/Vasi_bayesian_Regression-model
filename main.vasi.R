library(readxl)
library(dplyr)
library(rstan)
library(loo)
library(llbayesireg )
library(readxl)
library("simplexreg")
base_dir<-getwd()
source(file.path(base_dir,"codes","functions.R"))
set.seed(123)

##1. Read data 

df <- read_data("data_poverty_mg.csv")
df
#2. Descriptive Statistics
str(df)
summary(df)
head(df)
colSums(is.na(df))

#3. Covariates and response variable 

N <- nrow(df)
cov_x<-df[,2]
X <- cbind(1,cov_x)
Y <- rep(1,N)
y <-df[,3]
dat_stan <- list(N = N, X = as.matrix(X),Y=as.matrix(Y), r = 2, k = 1, y = y)
#4. Prepare Data for STAN-location model
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
# Define model files
model_files <- list(
  vasi = "models/stan_vasi.stan"#stan_vasi_mixed_loc #stan_vasi_mixed_loc_dis
  #beta = "models/stan_beta.stan",
  #simplex = "models/stan_simplex.stan"
  
)

# ── 4. Run and save function ──────────────────────────────────────────────────
run_stan_models <- function(model_files, dat_stan,
                            iter        = 5000,
                            warmup      = 2500,        # ← restored: half of iter
                            chains      = 1,
                            #seed        = 123,
                            results_dir = "results") { # ← added as parameter
  
  # Create results folder once at the start
  # Create results folder once at the start
  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE)
    cat("Created results directory:", results_dir, "\n")
  } else {
    cat("Results will be saved to existing directory:", results_dir, "\n")
  }
  
  results   <- list()
  estimates <- list()
  criteria_list <- list() 
  
  for (model_name in names(model_files)) {
    path <- model_files[[model_name]]
    cat("\n──────────────────────────────────────\n")
    cat("Running model:", model_name, "\n")
    cat("File        :", path, "\n")
    
    if (!file.exists(path)) {
      warning("Stan file not found, skipping: ", path)
      next
    }
    
    fit <- tryCatch(
      stan(
        file    = path,
        data    = dat_stan,
        iter    = iter,
        warmup  = warmup,      # ← now defined, no error
        chains  = chains,
        #seed    = seed,
        verbose = FALSE
      ),
      error = function(e) {
        message("ERROR in model '", model_name, "': ", conditionMessage(e))
        NULL
      }
    )
    
    if (is.null(fit)) next
    
    results[[model_name]] <- fit
    
    
    # Initialize criteria storage for this model
    model_criteria <- list()
    
    
    # Extract log_lik
    log_lik_matrix <- tryCatch(
      extract(fit, "log_lik")$log_lik,
      error = function(e) {
        message("Could not extract log_lik for model '", model_name, "': ", conditionMessage(e))
        NULL
      }
    )
    
    if (!is.null(log_lik_matrix)) {
      waic_obj <- waic(log_lik_matrix)
      loo_obj <- loo(log_lik_matrix)
      
      model_criteria$waic_value <- waic_obj$estimates["waic", "Estimate"]
      model_criteria$waic_se <- waic_obj$estimates["waic", "SE"]
      model_criteria$loo_value <- loo_obj$estimates["looic", "Estimate"]
      model_criteria$loo_se <- loo_obj$estimates["looic", "SE"]
      
      cat("\n  WAIC:", round(model_criteria$waic_value, 2))
      cat("\n  LOO: ", round(model_criteria$loo_value, 2))
    }
    
    # Extract EAIC and EBIC (if available)
    model_criteria$eaic <- tryCatch(
      mean(extract(fit, "EAIC")$EAIC),
      error = function(e) NA
    )
    
    model_criteria$ebic <- tryCatch(
      mean(extract(fit, "EBIC")$EBIC),
      error = function(e) NA
    )
    
    if (!is.na(model_criteria$eaic)) {
      cat("\n  EAIC:", round(model_criteria$eaic, 2))
      cat("\n  EBIC:", round(model_criteria$ebic, 2))
    }
    cat("\n")
    
    # Save criteria for this model
    criteria_list[[model_name]] <- model_criteria
    
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
    
    # Save stanfit object immediately after each model
    rds_path <- file.path(results_dir, paste0("stanfit_", model_name, ".rds"))
    saveRDS(fit, rds_path)
    cat("Stanfit saved :", rds_path, "\n")
    
    # Tidy summary
    summ <- summary(fit)$summary
    est  <- as.data.frame(summ) |>
      tibble::rownames_to_column("parameter") |>
      dplyr::mutate(model = model_name, .before = 1)
    
    estimates[[model_name]] <- est
    
    # Save per-model CSV immediately
    csv_path <- file.path(results_dir, paste0("stan_estimates_", model_name, ".csv"))
    write.csv(est, csv_path, row.names = FALSE)
    cat("Estimates saved:", csv_path, "\n")
    
    # Print key estimates
    cat("Key estimates:\n")
    print(
      est |>
        dplyr::filter(!grepl("lp__", parameter)) |>
        dplyr::select(model, parameter, mean, sd, `2.5%`, `97.5%`, Rhat, n_eff),
      digits = 3
    )
  }
  
# Save all criteria combined into one file
all_criteria <- do.call(rbind, lapply(names(criteria_list), function(m) {
  crit <- criteria_list[[m]]
  data.frame(
    model = m,
    waic = ifelse(is.null(crit$waic_value), NA, crit$waic_value),
    waic_se = ifelse(is.null(crit$waic_se), NA, crit$waic_se),
    loo = ifelse(is.null(crit$loo_value), NA, crit$loo_value),
    loo_se = ifelse(is.null(crit$loo_se), NA, crit$loo_se),
    eaic = crit$eaic,
    ebic = crit$ebic
  )
}))

all_criteria_path <- file.path(results_dir, "all_criteria.csv")
write.csv(all_criteria, all_criteria_path, row.names = FALSE)
cat("\n All criteria saved to:", all_criteria_path, "\n")

# Return results
list(
  fits = results, 
  estimates = estimates,
  criteria = criteria_list,
  all_criteria = all_criteria
)
}

# ── 5. Execute ────────────────────────────────────────────────────────────────
results_dir <- "results"
output <- run_stan_models(model_files, dat_stan, results_dir = "results")  # ← single call

# Access saved criteria later if needed
all_criteria <- output$all_criteria
print(all_criteria)

# Or access individual model criteria
if("prob_model" %in% names(output$criteria)) {
  cat("\nProb model criteria:\n")
  print(output$criteria[["prob_model"]])
}