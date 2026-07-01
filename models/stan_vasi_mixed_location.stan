functions{
  real probit_normal_lpdf(real y, real m, real s) {
    real z = inv_Phi(y);           // N&b;B9(y)
    real term = (z - m) / s;       // (N&b;B9(y) - m)/s
    real lprob = -log(s) - 0.5 * (term^2 - z^2);
    return lprob;
  }
  
  // Vectorized log-likelihood: sum over all y[i]
  real loglik_probit_normal(real[] y, real[] m, real[] s) {
    int N = num_elements(y);
    real lprob[N];
    for (i in 1:N) {
      lprob[i] = probit_normal_lpdf(y[i]| m[i], s[i]);
    }
    return sum(lprob);
  }
  
   // CDF function
  real probit_normal_cdf(real y, real m, real s) {
    real z = inv_Phi(y);           // inverse probit transform
    // Apply standard normal CDF to the standardized term
    return Phi((z - m) / s);
  }

}

data {
  int<lower=0> N;  // number of observations
  int<lower=0> r;   // number of predictors for mean
  int<lower=0> k;   // number of predictors for precision
  matrix[N, r] X;  // predictor variables
  matrix[N, k] Y;  // predictor variables
  int<lower=0> M;          // 25 departments
  int<lower=1> id[N];      // department index for each province
  //matrix[N, k] Y;  // predictor variables
  array[N] real<lower=0, upper=1> y;     // response variable
}

parameters {
  //real beta_0;
  vector[r] beta;//-2
  vector[k] gamma;
  real<lower=0> sigma2;
  real bi[M];
  //vector[k] gamma;// regression coefficients//-3
}

transformed parameters {
  array[N] real<lower=0, upper=1> mu;  // mean parameter
  array[N] real<lower=0, upper=1> psi;
  array[N] real m;             // parameter for probitn distn
  array[N] real<lower=0> s;             // parameter for probitn distn
  
  for (i in 1:N) {
    mu[i]  = inv_logit( X[i,] * beta + bi[id[i]]);   
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
  for(j in 1:M){
  bi[j] ~ normal(0,sigma2);
  }
  sigma2 ~ inv_gamma(0.01, 0.01); 
  beta ~ normal(0, 10);  // Prior for regression coefficients
  gamma~ normal(0, 10);
  //phi ~ inv_gamma(2, 2);  // Prior for precision
  
  // Likelihood
  target += loglik_probit_normal(y, m, s);
}

generated quantities{
  real dev;
  real log_lik[N];
  vector[N] cdf_sim;   // Vector to store the residuals
  dev=0;
  for (i in 1:N)
  {
    log_lik[i]= probit_normal_lpdf(y[i]| m[i], s[i]);
    cdf_sim[i]= probit_normal_cdf(y[i], m[i], s[i]);
    dev= dev+ (-2)*log_lik[i];
  }
  real likel=sum(log_lik);
  real EAIC= -2*likel+2*(r+k+1+25);
  real EBIC= -2*likel+log(N)*(r+k+1+25);


}

