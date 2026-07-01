functions{
real probit_normal_lpdf(real y, real m, real s) {
    if (y <= 0 || y >= 1) reject("y must be in (0,1), got ", y);
    if (s <= 0) reject("s must be positive, got ", s);
    real z = inv_Phi(y);
    real term = (z - m) / s;
    return -log(s) - 0.5 * (term^2 - z^2);
  }
  
  // Vectorized log-likelihood: sum over all y[i]
real loglik_probit_normal(array[] real y, array[] real m, array[] real s) {
  int N = num_elements(y);
  real total = 0;
  for (i in 1:N) {
    total += probit_normal_lpdf(y[i] | m[i], s[i]);
  }
  return total;
}
  
   // CDF function
 real probit_normal_cdf(real y, real m, real s) {
    if (y <= 0 || y >= 1) reject("y must be in (0,1), got ", y);
    real z = inv_Phi(y);
    return Phi((z - m) / s);
  }

}

data {
  int<lower=0> N;  // number of observations
  int<lower=0> r;   // number of predictors for mean
  int<lower=0> k;   // number of predictors for precision
  matrix[N, r] X;  // predictor variables
  matrix[N, k] Y;  // predictor variables
  //matrix[N, k] Y;  // predictor variables
  array[N] real<lower=0, upper=1> y;     // response variable
}

parameters {
  //real beta_0;
  vector[r] beta;//-2
  vector[k] gamma;
  //vector[k] gamma;// regression coefficients//-3
}

transformed parameters {
  array[N] real<lower=0, upper=1> mu;  // mean parameter
  array[N] real<lower=0, upper=1> psi;
  array[N] real m;             // parameter for probitn distn
  array[N] real<lower=0> s;             // parameter for probitn distn
  for (i in 1:N) {
    mu[i]  = inv_logit( X[i,] * beta);   
    //psi[i] = inv_logit(Y[i,] * gamma); //+ Y[i,] * gamma
    psi[i] =Phi(dot_product(Y[i], gamma));
    m[i] = inv_Phi(mu[i]) * sqrt(1/ (1-  psi[i] ));
    s[i] = sqrt( psi[i] / (1- psi[i]));
  }
  
  
}

model {
  // Priors
  //beta_0 ~ normal(0, 10);
  //psi ~ student_t(1, 0, 10);
  beta ~ normal(0, 100);  // Prior for regression coefficients
  gamma~ normal(0, 100);
  //phi ~ inv_gamma(2, 2);  // Prior for precision
  
  // Likelihood
  target += loglik_probit_normal(y, m, s);
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
    log_lik[i] = probit_normal_lpdf(y[i] | m[i], s[i]);
    cdf_sim[i] = probit_normal_cdf(y[i], m[i], s[i]);
    dev = dev + (-2) * log_lik[i];
  }

   likel=sum(log_lik);
   EAIC= -2*likel+2*(r+k);
  EBIC= -2*likel+log(N)*(r+k);

}

