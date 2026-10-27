functions {

  // Log-PDF for the Simplex distribution
  real simplex_lpdf(real y, real mu, real sigmasq) {
    if (y <= 0 || y >= 1)
      reject("simplex_lpdf: y must be in (0, 1), found y = ", y);
    if (mu <= 0 || mu >= 1)
      reject("simplex_lpdf: mu must be in (0, 1), found mu = ", mu);
    if (sigmasq <= 0)
      reject("simplex_lpdf: sigmasq must be positive, found sigmasq = ", sigmasq);

    real dev = square(y - mu) / (y * (1 - y) * square(mu) * square(1 - mu));
    real lprob = -0.5 * log(2 * pi() * sigmasq)
                 - 1.5 * (log(y) + log(1 - y))
                 - dev / (2 * sigmasq);
    return lprob;
  }

  // Log-likelihood over arrays
  real loglik_simplex(array[] real y, array[] real mu, array[] real sigmasq) {
    int N = num_elements(y);
    real lp = 0;
    for (i in 1:N)
      lp += simplex_lpdf(y[i] | mu[i], sigmasq[i]);
    return lp;
  }
  
  real simplex_cdf(real y, real mu, real sigmasq) {
    if (y <= 0 || y >= 1)   reject("y must be in (0,1), got ", y);
    if (mu <= 0 || mu >= 1) reject("mu must be in (0,1), got ", mu);
    if (sigmasq <= 0)        reject("sigmasq must be positive, got ", sigmasq);
    int M = 1000;
    real step = y / M;
    real total = 0;
    for (j in 1:M) {
      real t = (j - 0.5) * step;   // midpoint rule
      total += exp(simplex_lpdf(t | mu, sigmasq)) * step;
    }
    return total;
  }
  
  

}

data {
  int<lower=0> N;  // number of observations
  int<lower=0> r;   // number of predictors for mean
  int<lower=0> k;   // number of predictors for precision
  matrix[N, r] X;  // predictor variables
  matrix[N, k] Y;  // predictor variables
  array[N] real<lower=0, upper=1>y;     // response variable
}

parameters {
  //real beta_0;
  //real gamma_0;
  vector[r] beta;
  vector[k] gamma;
  //vector[s] epsilon;// regression coefficients
  
}

transformed parameters {
  array[N] real<lower=0, upper=1> mu;  // mean parameter
  array[N] real<lower=0> sigmasq;  // precision parameter
  //vector<lower=0>[N] A;             // parameter for beta distn
  //vector<lower=0>[N] B;             // parameter for beta distn
  //real<lower=0, upper=1> phi;  // mean parameter
  //mu = inv_logit(alpha +X * beta);  // Linear predictor transformed to (0, 1) range
  
  for (i in 1:N) {
    mu[i]  = inv_logit(X[i,] * beta);   
    sigmasq[i] = exp(Y[i,] * gamma);
  }

  //A = mu .* phi;
  //B = (1.0 - mu) .* phi;
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
  target += loglik_simplex(y, mu, sigmasq);
}

generated quantities {
 array[N] real log_lik;
  vector[N] cdf_sim;
  real dev;
  real likel;
  real EAIC;
  real EBIC;
  dev = 0;
  for(i in 1:N) {
    log_lik[i] = simplex_lpdf(y[i] | mu[i], sigmasq[i]);  // ← uses A[i], B[i] from transformed params
  cdf_sim[i]= simplex_cdf(y[i], mu[i], sigmasq[i]);
   dev = dev + (-2) * log_lik[i];
  }
  
  likel=sum(log_lik);
  EAIC= -2*likel+2*(r+k);
  EBIC= -2*likel+log(N)*(r+k);
}


