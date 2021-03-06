#####################################################################################
# 1. DESCRIPTION:
#####################################################################################

#####################################################################################
# 2. LIBRAIRIES:
#####################################################################################
library("rjson")
library("readr")
library("purrr")
library("tidyr")
library("tibble")
library("plyr")
library("corrplot")
library("FactoMineR")
library("dplyr")
library("caret")
library("jtools")
library("broom.mixed")
library("glmnet")
library("tidyverse")
library("tibble")
setwd("/home/renoult/Bureau/thesis/code/functions")
#####################################################################################
# 3. Fonctions
#####################################################################################

######################
#3.1 AIC/BIC
######################
glmnet_cv_aicc <- function(fit, lambda = 'lambda.1se'){
  
  whlm <- which(fit$lambda == fit[[lambda]])

  with(fit$glmnet.fit,
       {
         tLL <- nulldev - nulldev * (1 - dev.ratio)[whlm]
         k <- df[whlm]
         n <- nobs
         return(list('AICc' = - tLL + 2 * k + 2 * k * (k + 1) / (n - k - 1),
                     'BIC' = log(n) * k - tLL))
       })
}
######################
#3.2 BIG FUNCTION
######################
kfold_gini <- function(bdd, weight, metric, layer, regularization, print_number) {
  
  print('######')
  print(layer)
  ######################
  # 3.2.1 DATA MANAGEMENT
  ######################
  labels_path = paste('../../data/redesigned/',bdd,'/labels_',bdd,'.csv', sep="")
  log_path =paste('../../results/',bdd,'/pca/', sep="")
  log_path_rate =paste('../../results/',bdd,'/log_', sep="")
  
  #chargement du fichier
  df_pc = read_csv(file = paste(log_path,"pca_values_",layer,".csv", sep =""), show_col_types = FALSE)
  df_pc = df_pc[,-1]
  
  #on récupère les notes de beauté
  matrix_metrics <- do.call(cbind, fromJSON(file = paste(log_path_rate,'_',bdd,'_',weight,'_',metric,'_','_BRUTMETRICS','.csv',sep=""),simplify = FALSE))
  df_metrics <- as.data.frame(matrix_metrics, optional = TRUE)
  df_metrics = sapply(df_metrics, as.numeric)
  df_metrics <- as.data.frame(df_metrics)
  df = cbind(df_metrics$rate, df_pc)
  df <- plyr::rename(df, c("df_metrics$rate" = "rate"))
  
  ###########################################################
  #3.2.2Itérations sur les différents seuils de variance expliquée
  ############################################################
  
  #chargement du fichier de somme cumulée de variance expliquée par composante
  log_variance =paste('../../results/',bdd,'/pca_variance/', sep="")
  df_variance = read_csv(file = paste(log_variance,"varianceCumule_",layer,".csv", sep =""), show_col_types = TRUE)
  df_variance = df_variance[,-1]
  
  #définition des seuils, en %
  variances = c(30) #c(20,30,40,50,60,70,80)
  var_tresholds = c()
  
  #création d'un vecteur contenant l'indice de la dernière variable pour chaque seuil
  for (variance in variances) {
    var_treshold = which(df_variance[1,] <= variance, arr.ind = F)
    var_treshold = tail(var_treshold, n=1)
    var_tresholds = c(var_tresholds,var_treshold)
  }
  
  AICs = c()
  BICs = c()
  R_squareds = c()
  all_models = c()
  
  for (treshold in var_tresholds) {
    ###############################
    # 3.2.3. MODEL: REGRESSION WITH REGULARIZATION (ridge, lasso or elasticnet)
    ###############################
    treshold = treshold + 1 #pour prendre en compte la colonne "rate"
    print('####TRESHOLD:')
    print(treshold)
    
    temp_df = df[,1:treshold]
    
    ctrl = trainControl(method = "repeatedcv", number = 10) #10-fold cv
    model1 = train( rate ~ ., data = temp_df ,method = regularization,preProc = c("center", "scale"),trControl = ctrl, metric = "Rsquared")
    
    alpha = model1$results$alpha[1]
    lambda = model1$results$lambda[1]
    r_squared = model1$results$Rsquared[1]
    
    matrix = as.matrix(temp_df)
    x = matrix[,-1]
    y = matrix[,1]
    if (regularization == 'glmnet'){
      model2 = cv.glmnet(x, y, alpha = alpha)
    } else if (regularization == 'lasso'){
      model2 = cv.glmnet(x, y, alpha = 1)
    } else { #cad regularization = ridge
      model2 = cv.glmnet(x, y, alpha = 0)
    }
    
    coefs = coef(model2)
    print(" ## number of nonzero coefficients : ")
    print(length(coefs@x))
    print("percentage of non 0 coefficients:")
    print((length(coefs@x)/treshold)*100)
    
    
    criterions =  glmnet_cv_aicc(model2, lambda =  'lambda.min')
    
    AICs = c(AICs, criterions$AICc)
    BICs = c(BICs, criterions$BIC)
    R_squareds = c(R_squareds, r_squared)
  }
  
 
  list = list('r_squareds' = R_squareds, 'AIC'= AICs, 'BIC'= BICs)
  return(list)
}
#####################################################################################
# 4. PARAMETERS:
#####################################################################################
bdd <- c('CFD')
weight <- c('imagenet')
metric <- c('gini_flatten')
layers <-  c( 'block1_conv1','block1_conv2',
              'block2_conv1','block2_conv2',
              'block3_conv1','block3_conv2','block3_conv3',
              'block4_conv1','block4_conv2','block4_conv3',
              'block5_conv1','block5_conv2','block5_conv3'
              )
regularization <- 'lasso' #ridge for ridge, lasso for lasso, glmnet for elasticnet
print_number = 200

set.seed(123)

######################################################################################
# 5. MAIN:
######################################################################################
R_squareds = c()
AICs = c()
BICs = c()
vector_tresholds = c()
models = c()
######################
#5.1 Loop on kfold_gini's function for each layer
######################
for (layer in layers){
  results = kfold_gini(bdd, weight, metric, layer, regularization, print_number)
  
  R_squareds = c(R_squareds, results$r_squareds)
  AICs = c(AICs, results$AIC)
  BICs = c(BICs, results$BIC)
}


################################################
#5.2 Plots of mean AIC for each percentage######
################################################

tresholds_index = c(0,1,2,3,4,5,6)
max_AIC_per_percentage = c()
max_BIC_per_percentage = c()
max_R_squareds_per_percentage = c()

for (index in tresholds_index) { 

  list_AIC = c(AICs[1+index],AICs[8+index],AICs[15+index],AICs[22+index],AICs[29+index],AICs[36+index],AICs[43+index],AICs[50+index],AICs[57+index],AICs[64+index],AICs[71+index],
               AICs[78+index],AICs[85+index],AICs[92+index],AICs[99+index])
  
  list_BIC = c(BICs[1+index],BICs[8+index],BICs[15+index],BICs[22+index],BICs[29+index],BICs[36+index],BICs[43+index],BICs[50+index],BICs[57+index],BICs[64+index],BICs[71+index],
               BICs[78+index],BICs[85+index],BICs[92+index],BICs[99+index])
  
  list_R_squareds = c(R_squareds[1+index],R_squareds[8+index],R_squareds[15+index],R_squareds[22+index],R_squareds[29+index],R_squareds[36+index],R_squareds[43+index],R_squareds[50+index],R_squareds[57+index],R_squareds[64+index],R_squareds[71+index],
                      R_squareds[78+index],R_squareds[85+index],R_squareds[92+index],R_squareds[99+index])
  
  max_AIC_per_percentage = c(max_AIC_per_percentage, min(list_AIC))
  max_BIC_per_percentage = c(max_BIC_per_percentage, min(list_BIC))
  max_R_squareds_per_percentage = c(max_R_squareds_per_percentage, median(list_R_squareds))
}

percentages = c('20%','30%','40%','50%','60%','70%','80%')

barplot(max_AIC_per_percentage, names.arg = percentages, xlab = "percentages", ylab= "AIC", main = cbind('AIC_min_',bdd,'_',regularization))
barplot(max_BIC_per_percentage, names.arg = percentages, xlab = "percentages", ylab= "BIC", main = cbind('BIC_min_',bdd,'_',regularization))
barplot(max_R_squareds_per_percentage, names.arg = percentages, xlab = "percentages", ylab= "R_squareds_max", main = cbind('R_squareds_median_',bdd,'_',regularization))



######################################



print('## R2 ##')
print(R_squareds)
print('## AICs ##')
print(AICs)
print('## BICs ##')
print(BICs)

barplot(R_squareds, names.arg = layers, xlab = "layers", ylab= "rsquared", main = cbind('R2_',bdd,'_',regularization))
barplot(AICs, names.arg = layers, xlab = "layers", ylab= "AIC", main = cbind('AIC_',bdd,'_',regularization))
barplot(BICs, names.arg = layers, xlab = "layers", ylab= "BIC", main = cbind('BIC_',bdd,'_',regularization))


######################################################################################
# 6. TEST SANS FONCTION:
######################################################################################
