#####################################################################################
# 1. DESCRIPTION:
#####################################################################################

#####################################################################################
# 2. LIBRAIRIES:
#####################################################################################
library("rjson")
library("purrr")
library("tidyr")
library("tibble")
library("plyr")
library("corrplot")
library("dplyr")
library("caret")
library("jtools")
library("broom.mixed")
library("glmnet")
setwd("/home/renoult/Bureau/thesis/code/functions")
#####################################################################################
# 3. PARAMETERS:
#####################################################################################
model_name <- 'VGG16'
bdd <- c('MART')
weight <- c('imagenet')
metric <- c('gini_flatten')
subset_db1 = 700
#####################################################################################
# 4. DATA MANAGEMENT
#####################################################################################
labels_path = paste('../../data/redesigned/',bdd,'/labels_',bdd,'.csv', sep="")
log_path =paste('../../results/',bdd,'/log_', sep="")

#chargement du fichier
matrix_metrics <- do.call(cbind, fromJSON(file = paste(log_path,'_',bdd,'_',weight,'_',metric,'_','_BRUTMETRICS','.csv',sep=""),simplify = FALSE))

#si on ne fait pas ça, l'input peut avoir un indice variable
colnames(matrix_metrics)[2] <- 'input_1'

#idem avec les calculs de complexité
matrix_complexity <- do.call(cbind, fromJSON(file = paste(log_path,'_',bdd,'_',weight,'_','mean','_','_BRUTMETRICS','.csv',sep=""),simplify = FALSE))
colnames(matrix_complexity)[2] <- 'input_1'

#passage des matrice en dataframe
df_metrics <- as.data.frame(matrix_metrics, optional = TRUE)
df_complexity <- as.data.frame(matrix_complexity, optional = TRUE)        
#passage en flottants (avant c'était des strings)
df_metrics = sapply(df_metrics, as.numeric)
df_complexity = sapply(df_complexity, as.numeric)

#il faut repasser en df après le sapply
df_metrics <- as.data.frame(df_metrics)
df_complexity <- as.data.frame(df_complexity[,-1])

#changement des noms de colonne pour les uniformiser car les differents weights ont des noms de layers différents
df_metrics = plyr::rename(df_metrics, c("input_1" = "input_1",
                                        'block1_conv1'='conv1_1','block1_conv2'='conv1_2','block1_pool'='pool1',
                                        'block2_conv1'='conv2_1','block2_conv2'='conv2_2','block2_pool'='pool2',
                                        'block3_conv1'='conv3_1','block3_conv2'='conv3_2','block3_conv3'='conv3_3','block3_pool'='pool3',
                                        'block4_conv1'='conv4_1','block4_conv2'='conv4_2','block4_conv3'='conv4_3','block4_pool'='pool4',
                                        'block5_conv1'='conv5_1','block5_conv2'='conv5_2','block5_conv3'='conv5_3','block5_pool'='pool5',
                                        'flatten'='flatten','fc1'='fc6_relu','fc2'='fc7_relu'))
#même démarche pour la complexité
df_complexity = plyr::rename(df_complexity, c("input_1" = "input_1_comp",
                                              'block1_conv1'='conv1_1_comp','block1_conv2'='conv1_2_comp','block1_pool'='pool1_comp',
                                              'block2_conv1'='conv2_1_comp','block2_conv2'='conv2_2_comp','block2_pool'='pool2_comp',
                                              'block3_conv1'='conv3_1_comp','block3_conv2'='conv3_2_comp','block3_conv3'='conv3_3_comp','block3_pool'='pool3_comp',
                                              'block4_conv1'='conv4_1_comp','block4_conv2'='conv4_2_comp','block4_conv3'='conv4_3_comp','block4_pool'='pool4_comp',
                                              'block5_conv1'='conv5_1_comp','block5_conv2'='conv5_2_comp','block5_conv3'='conv5_3_comp','block5_pool'='pool5_comp',
                                              'flatten'='flatten_comp','fc1'='fc6_relu_comp','fc2'='fc7_relu_comp'))


#création d'un dataframe avec la complexité, la sparsité approximée par gini
df <- cbind(df_metrics, df_complexity)

#Z-transformation (centré réduit)
scaled_df <- scale(df[,-1]) #df[,-1] pour ne pas z transformer la beauté
df <- cbind(df$rate ,scaled_df) #si on avait pas scaled la beauté il aurait fallu la remettre
#df = scaled_df
df<- as.data.frame(df, optional = TRUE)
df <- plyr::rename(df, c("V1" = "rate"))

#shuffle for subsets
#rows <- sample(nrow(df))
#df = df[rows,]
#df = df[1:subset_db1,]


#####################################################################################
# 5. MODEL: RIDGE REGRESSION
#####################################################################################

#on va itérer sur les couches, il faut donc leurs noms
layers = c('input_1','conv1_1','conv1_2','pool1','conv2_1','conv2_2','pool2',
           'conv3_1','conv3_2','conv3_3','pool3','conv4_1','conv4_2','conv4_3','pool4',
           'conv5_1','conv5_2','conv5_3','pool5','flatten','fc6/relu','fc7/relu')

variables = colnames(df[,-1])

matrix = as.matrix(df)

k = nrow(matrix)
print(k)

set.seed(123)

lambdas = c()
predictions = c()

for (i in 1:k){
  
  print(i)
  
  train = matrix[-i,]
  test = matrix[i,]
  
  x_train = train[,-1]
  y_train = train[,1]
  
  cv_train <- cv.glmnet(x_train, y_train, alpha = 1) #alpha = 0 fait une ridge regression (1 si lasso)
  
  model <- glmnet(x_train, y_train, alpha = 1, lambda = cv_train$lambda.min)
  
  lambdas = c(lambdas, cv_train$lambda.min)
  
  #elastic net
  
  #model <- train(
  #  rate ~., data = train, method = "glmnet",
  #  trControl = trainControl("cv", number = 10),
  #  tuneLength = 10
  #)

  
  
  #predictions:
  x_test = test[-1]
  prediction <- model %>% predict(x_test) %>% as.vector()

  predictions = c(predictions, prediction)
  

} 

matrix <- cbind(predictions ,matrix)
Rsquare = R2(matrix[,1], matrix[,2])
print(Rsquare)





