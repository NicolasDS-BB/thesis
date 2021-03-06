####################################################################################
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
bdd <- c('CFD')
bdd2 <- c('SCUT-FBP')
weight <- c('imagenet')
metric <- c('gini_flatten')
#subset_db1 = 1563 #5000 scut, 827 cfd, 500 MART, 1563 JEN
#####################################################################################
# 4. DATA MANAGEMENT
#####################################################################################

#####################################################################################
# 4.1 database_1
#####################################################################################

labels_path = paste('../../data/redesigned/',bdd,'/labels_',bdd,'.csv', sep="")
log_path =paste('../../results/',bdd,'/log_', sep="")

#chargement du fichier
matrix_metrics <- do.call(cbind, fromJSON(file = paste(log_path,'_',bdd,'_',weight,'_',metric,'_','_BRUTMETRICS','.csv',sep=""),simplify = FALSE))

#si on ne fait pas ça, l'input peut avoir un indice variable
colnames(matrix_metrics)[2] <- 'input_1'

#passage des matrice en dataframe
df_metrics <- as.data.frame(matrix_metrics, optional = TRUE)
       
#passage en flottants (avant c'était des strings)
df_metrics = sapply(df_metrics, as.numeric)

#il faut repasser en df après le sapply
df_metrics <- as.data.frame(df_metrics)

#changement des noms de colonne pour les uniformiser car les differents weights ont des noms de layers différents
df = plyr::rename(df_metrics, c("input_1" = "input_1",
                                        'block1_conv1'='conv1_1','block1_conv2'='conv1_2','block1_pool'='pool1',
                                        'block2_conv1'='conv2_1','block2_conv2'='conv2_2','block2_pool'='pool2',
                                        'block3_conv1'='conv3_1','block3_conv2'='conv3_2','block3_conv3'='conv3_3','block3_pool'='pool3',
                                        'block4_conv1'='conv4_1','block4_conv2'='conv4_2','block4_conv3'='conv4_3','block4_pool'='pool4',
                                        'block5_conv1'='conv5_1','block5_conv2'='conv5_2','block5_conv3'='conv5_3','block5_pool'='pool5',
                                        'flatten'='flatten','fc1'='fc6_relu','fc2'='fc7_relu'))

#Z-transformation (centré réduit)
scaled_df <- scale(df[,-1]) 
df <- cbind(df$rate ,scaled_df) 
#df = scaled_df
df<- as.data.frame(df, optional = TRUE)
df <- plyr::rename(df, c("V1" = "rate"))

#subset
#set.seed(173)
#df = df[sample(1:nrow(df)), ]
#df = df[1:subset_db1,]

#####################################################################################
# 4.2 database_2
#####################################################################################

labels_path2 = paste('../../data/redesigned/',bdd2,'/labels_',bdd2,'.csv', sep="")
log_path2 =paste('../../results/',bdd2,'/log_', sep="")

#chargement du fichier
matrix_metrics2 <- do.call(cbind, fromJSON(file = paste(log_path2,'_',bdd2,'_',weight,'_',metric,'_','_BRUTMETRICS','.csv',sep=""),simplify = FALSE))

#si on ne fait pas ça, l'input peut avoir un indice variable
colnames(matrix_metrics2)[2] <- 'input_1'

#idem avec les calculs de complexité
matrix_complexity2 <- do.call(cbind, fromJSON(file = paste(log_path2,'_',bdd2,'_',weight,'_','mean','_','_BRUTMETRICS','.csv',sep=""),simplify = FALSE))


#passage des matrice en dataframe
df_metrics2 <- as.data.frame(matrix_metrics2, optional = TRUE)
       
#passage en flottants (avant c'était des strings)
df_metrics2 = sapply(df_metrics2, as.numeric)


#il faut repasser en df après le sapply
df_metrics2 <- as.data.frame(df_metrics2)


#changement des noms de colonne pour les uniformiser car les differents weights ont des noms de layers différents
df2 = plyr::rename(df_metrics2, c("input_1" = "input_1",
                                        'block1_conv1'='conv1_1','block1_conv2'='conv1_2','block1_pool'='pool1',
                                        'block2_conv1'='conv2_1','block2_conv2'='conv2_2','block2_pool'='pool2',
                                        'block3_conv1'='conv3_1','block3_conv2'='conv3_2','block3_conv3'='conv3_3','block3_pool'='pool3',
                                        'block4_conv1'='conv4_1','block4_conv2'='conv4_2','block4_conv3'='conv4_3','block4_pool'='pool4',
                                        'block5_conv1'='conv5_1','block5_conv2'='conv5_2','block5_conv3'='conv5_3','block5_pool'='pool5',
                                        'flatten'='flatten','fc1'='fc6_relu','fc2'='fc7_relu'))


#Z-transformation (centré réduit)
scaled_df2 <- scale(df2[,-1]) #df[,-1] pour ne pas z transformer la beauté
df2 <- cbind(df2$rate ,scaled_df2) #si on avait pas scaled la beauté il aurait fallu la remettre
#df = scaled_df
df2<- as.data.frame(df2, optional = TRUE)
df2 <- plyr::rename(df2, c("V1" = "rate"))


#####################################################################################
# 5. MODEL: RIDGE REGRESSION
#####################################################################################


matrix = as.matrix(df)
matrix2 = as.matrix(df2)

############
#model
###########

ctrl = trainControl(method = "repeatedcv", number = 10, repeats = 10) #10-fold cv
lambdas = 10^seq(2,-4,by=-0.1)
model = train( rate ~ ., data = df ,method = "glmnet", tuneGrid = expand.grid(alpha = 0, lambda = lambdas),preProc = c("center", "scale"),trControl = ctrl, metric = "Rsquared") #alpha = 0 pour ridge (1 pour lasso)

############
#predictions:
###########
  
#on prédit les notes de beauté du test en fonction du model issu du train
x_test = df2[,-1]
prediction <- model %>% predict(x_test) %>% as.vector()
  
#on fait la corrélation entre les valeurs de beauté prédites et réelles
Rsquare = R2(df2[,1], prediction)
print(Rsquare)
