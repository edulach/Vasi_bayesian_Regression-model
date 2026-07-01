functions {

  // --- Scalar log-PDF: Beta parameterized by mean (mu) and precision (phi) ---
  real beta_mu_phi_lpdf(real y, real mu, real phi) {
    if (y <= 0 || y >= 1)   reject("beta_mu_phi_lpdf: y must be in (0,1), got ", y);
    if (mu <= 0 || mu >= 1) reject("beta_mu_phi_lpdf: mu must be in (0,1), got ", mu);
    if (phi <= 0)            reject("beta_mu_phi_lpdf: phi must be positive, got ", phi);

    return beta_lpdf(y | mu * phi, (1.0 - mu) * phi);  // calls Stan built-in
  }

  // --- Vectorized log-likelihood: sum over all y[i] ---
  real loglik_mu_phi_beta(array[] real y, array[] real mu, array[] real phi) {
    int N = num_elements(y);
    real total = 0;
    for (i in 1:N)
      total += beta_mu_phi_lpdf(y[i] | mu[i], phi[i]);
    return total;
  }

  // --- CDF: Beta parameterized by mean (mu) and precision (phi) ---
  real beta_mu_phi_cdf(real y, real mu, real phi) {
    if (y <= 0 || y >= 1)   reject("beta_mu_phi_cdf: y must be in (0,1), got ", y);
    if (mu <= 0 || mu >= 1) reject("beta_mu_phi_cdf: mu must be in (0,1), got ", mu);
    if (phi <= 0)            reject("beta_mu_phi_cdf: phi must be positive, got ", phi);

    real alpha    = mu * phi;
    real beta_par = (1.0 - mu) * phi;

    return beta_cdf(y | alpha, beta_par);  // calls Stan built-in
  }

}

data {
  int<lower=0> N;  // number of observations
  int<lower=0> r;   // number of predictors for mean
  int<lower=0> k;   // number of predictors for precision
  matrix[N, r] X;  // predictor variables
  matrix[N, k] Y;  // predictor variables
  array[N] real<lower=0, upper=1> y;      // response variable
}

parameters {
  //real beta_0;
  //real gamma_0;
  vector[r] beta;//-2
  vector[k] gamma;
  //vector[s] epsilon;// regression coefficients
  
}

transformed parameters {
  array[N] real<lower=0, upper=1> mu;  // mean parameter
  array[N] real<lower=0> phi;
  //array[N] real A;             // parameter for beta distn
  //array[N] real B;             // parameter for beta distn
  //real<lower=0, upper=1> phi;  // mean parameter
  //mu = inv_logit(alpha +X * beta);  // Linear predictor transformed to (0, 1) range
  
  for (i in 1:N) {
    mu[i]  = inv_logit(X[i,] * beta);   
    phi[i] = exp(Y[i,] * gamma); 
    //A[i]   = mu[i] * phi[i];           
    //B[i]   = (1.0 - mu[i]) * phi[i];  
}
}
  //mu = inv_logit(alpha+ X * beta);
  //phi = exp(delta+ X * epsilon);


model {
  // Priors
  //beta_0 ~ normal(0, 10);
  //phi ~ student_t(1, 0, 10);
  beta ~ normal(0, 100);  // Prior for regression coefficients
  gamma ~ normal(0, 100);  // Prior for regression coefficients
  //epsilon~ normal(0, 10);
  
  // Likelihood
  //for (n in 1:N) {
   //y[n] ~ beta(A[n], B[n]);
   target += loglik_mu_phi_beta(y, mu, phi);
  //}
}

generated quantities{
  array[N] real log_lik;
  vector[N] cdf_sim;
  real dev;
  real likel;
  real EAIC;
  real EBIC;
  dev = 0;
  for (i in 1:N) {
    log_lik[i] = beta_mu_phi_lpdf(y[i] | mu[i], phi[i]);
    cdf_sim[i] = beta_mu_phi_cdf(y[i], mu[i], phi[i]);
    dev = dev + (-2) * log_lik[i];
  }

 likel = sum(log_lik);
  EAIC  = -2 * likel + 2 * (r + k);
  EBIC  = -2 * likel + log(N) * (r + k);

}




