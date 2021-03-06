#!/usr/bin/env python
#####################################################################################
# DESCRIPTION:
#####################################################################################
#[EN]Main program of the PCA calculation on the activations of the intermediate layers of VGG16
#Output: image coordinates for each layer, for the PCA components representing 80% of the explained variance
#The goal is then to create a model under R (for example an e ridge regression in leave one out cross validation) with these values as explanatory variables and the beauty/attractiveness as variable to explain
# Loop on the combinatorics of the parameters (databases, weights, model etc)

#[FR]Programme principal du calcul d'ACP sur les activations des couches intermédiaires de VGG16
#Sortie: coordonnées des images pour chaque couche, pour les composantes de l'ACP représentant 80% de la variance expliquée
#Le but étant ensuite de créer un modèle sous R (par exemple un e ridge regression en leave one out cross validation) avec ces valeurs en variables explicatives et la beauté/attractivité en variable à expliquer
# Boucle sur les combinatoires des paramètres (bases de données, poids, modèle etc)
# Choix de ces paramètres ci dessous. 

#####################################################################################
# LIBRAIRIES:
#####################################################################################
#public librairies
import os
os.environ['TF_XLA_FLAGS'] = '--tf_xla_enable_xla_devices'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import PIL
import sys
#personnal librairies
sys.path.insert(1,'../../code/functions')
import sparsenesslib.high_level as hl
#####################################################################################
#SETTINGS:
#####################################################################################
PIL.Image.MAX_IMAGE_PIXELS = 30001515195151997
478940                             
#'CFD','SCUT-FBP','MART','JEN','SMALLTEST','BIGTEST'
list_bdd = ['CFD'] #"['CFD','MART','JEN','SCUT-FBP','SMALLTEST','BIGTEST']"
model_name = 'VGG16'  # 'vgg16, resnet (...)'
#weights = 'vggface' #'imagenet','vggface'
list_weights = ['imagenet'] #['vggface','imagenet','vggplace']
computer = 'LINUX-ES03' #no need to change that unless it's sonia's pc, that infamous thing; in which case, put 'sonia' in parameter.
freqmod = 100 #frequency of prints, if 5: print for 1/5 images
#####################################################################################
#CODE
#####################################################################################
list_metrics = ['acp']
k = 1
l = len(list_bdd)*len(list_weights)*len(list_metrics)
for bdd in list_bdd:    
    for weight in list_weights:
        for metric in list_metrics:
            print('###########################--COMPUTATION--#################################_STEP: ',k,'/',l,'  ',bdd,', ',weight,', ',metric)
            hl.extract_pc_acp_filter(bdd,weight,metric, model_name, computer, freqmod,k)            
            k += 1
#####################################################################################
