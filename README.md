# A New Mean-Dispersion Bounded Mixed Regression Model
Victor Eduardo Lachos Olivares <sup>1</sup> and Jorge Luis Bazán Guzmán<sup>2</sup>Catalina B. García-García<sup>3</sup>

<sup>1</sup>Department of Statistics at the Federal University of São Carlos (UFSCar) and the Department of Applied Mathematics and 
Statistics at the Institute of Mathematical and Computer Sciences of the University of São Paulo (ICMC-USP), São Carlos, Brazil.
<sup>2</sup>Department of Applied Mathematics and Statistics, University of São Paulo, São Carlos, Brazil.
<sup>3</sup>Department of Quantitative Methods for Economics and Business, University of Granada, Spain.

Corresponding Authors: Eduardo Lachos Olivares: velo28@usp.br 

This material serves as a supplementary resource to the paper "A New Mean-Dispersion Bounded Mixed Regression Model"
## Previous installations

- Running the scripts requires the STAN software, which is installed via the RStan package. Installation instructions can be found in:
Guo, J., Gabry, J., Goodrich, B., & Weber, S. (2020). Package ‘rstan’. URL https://cran. r―project.
A supplementary guide is available at: [https://www.jstatsoft.org/index.php/jss/article/view/v012i03/33](https://pj.freefaculty.org/guides/crmda_workshops/sem/Archive/sem-4/literature/manuals/rstan.pdf)

## File description:

The project includes the following files and folders:
- main.probit.R: This script contains the code to read the data from the file datasets. It utilizes two primary datasets:
data_poverty_mg.csv
datapov_peru.csv

- datasets: This folder contains the data of poverty from Mato Grosso(MG) in 2010 with two variables Proportion of out-of-school children aged 6–14
  and the respective Human development indicator by municipality, and data of poverty from regions of Peru with the extreme poverty and the Human development indicator by municipality.
-codes: it contains the functions.R for reading the dataset, which can be in format .csv, .txt, .xls, and .xlsx.
- models: This folder contains the codes in stan, which includes for Beta, Simplex and Probit-Normal as well as the codes
 for Mixed regression Probit-Normal model introducing random effects in mean and dispersion parameters.

## Instructions for Running R and RStan Codes

Open main.probit.R in R and specify the the dataset to be run. It should follow the format specified in folder datasets.
. Then, run the script.

The default Stan model settings are preconfigured as follows: 

iter = 5000
warmup  = 2500
chains = 1
However, it can be configurated. The model also estimate the criteria  waic and loo from \texttt{loo} package, 
and the criteria EAIC and EBIC, which will be saved in a folder "results" with the estimates obtained from the chosen model.
   
