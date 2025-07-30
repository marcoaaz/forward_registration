
#R Script to run from MatLab software pipeline

#With this script we want to obtain the REE imputed values and lambda parameters.
#These include:
#the average ΣREEs concentration (λ0), 
#the slope (λ1), 
#the curvature (λ2) and 
#the inflections at the extremes of the pattern (λ3).

#Documentation: 
#https://cran.r-project.org/web/packages/imputeREE/index.html

#Installs required:
#install.packages("magrittr") 
#install.packages("devtools")

#Function notes:

#model_REE
#method
#=1 for Chondrite Lattice, 
#=2 for Zhong et al. (2019), or 
#=3 for Chondrite-Onuma method.

#chondrite
#=PalmeOneill2014CI, 
#=Oneill2014Mantle, or
#=McDonough1995CI

#Calibrate= If True, the model is calibrated using the correction factors
#exclude= La, Ce and Eu are the default elements omitted from modelling (not prediction).

#impute_REE
#r-squared = Tolerance to misfitting models. set as 0.9 by default.
#The Chondrite-Lattice method should consider R-squared > 0.95 for at least 3 points. 
#The Chondrite-Onuma method should consider R-squared >0.98 for at least 4 points.

#Note 1: Ho, Tm, Tb were fabricated values to debug impute_REE. They must be excluded
#Note 2: For samples with less than 3 or less elements do not produce a model.  
#For them, consider filtering that data, or including more elements 
#Note 3: Gd, Er, Y cannot be missing values at the same time. Equidistance condition.

#Created: 1-Aug-24, Marco Acevedo
#Updated: 30-Apr-25

## 

library(magrittr)
library(imputeREE) 
library(beepr)
library(dplyr)

#User input
args <- commandArgs(TRUE)
model_chosen <- 3

#Script
sourceDir <- as.character(args[1]) #\\ also allowed

file1 = 'input_Carrasco.csv'
file2 = 'output_Carrasco.csv'
filepath1 = file.path(sourceDir, file1)
filepath2 = file.path(sourceDir, file2) #imputation_output_Chondrite Lattice

input_table <- read.csv(filepath1)
columnNames = colnames(input_table)
columnNames2 = columnNames[4:length(columnNames)]

#Medicine 1: optional depending on quality/unavailability (see experiment)
#input_table["Ho"][input_table["Ho"] == 0.1] <- NaN
#input_table["Tm"][input_table["Tm"] == 0.1] <- NaN
#input_table["Tb"][input_table["Tb"] == 0.1] <- NaN

if (model_chosen == 3) {
  rsquared_chosen <- 0.98   
  
} else if (model_chosen == 1) {
  rsquared_chosen <- 0.95
  
} else if (model_chosen == 2) {
  rsquared_chosen <- 0.9 #default
} 

#Run
output_table <- input_table %>%

model_REE(prefix = NULL, suffix = NULL, 
          method = model_chosen, 
          exclude = c("La", "Pr", "Ce", "Eu", "Y", "Ho", "Tm", "Tb"),
          chondrite = PalmeOneill2014CI,
          Calibrate = T) %>%
impute_REE(prefix = NULL, suffix = NULL, rsquared = rsquared_chosen)

output_table2 <- output_table

#Medicine: change column names
#colnames(output_table2)[which(names(output_table2) == "Ce/Ce*")] <- "Ce_ratio_A"

#Save
write.table(output_table2, file = filepath2, sep = ",", col.names=TRUE, row.names = FALSE) 


