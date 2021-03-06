#!/usr/bin/env python
#####################################################################################
# DESCRIPTION:
#####################################################################################
#[EN] fichier dans le cadre du stage de Melvin
#[FR]

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
pathData = '../../'

pathLLH = ""

if len(sys.argv) >1:
    if sys.argv[1]== 'mesoLR':
        sys.path.insert(1,'/home/tieos/work_swp-gpu/melvin/thesis/code/functions')
        pathData = '/home/tieos/work_swp-gpu/melvin/thesis/'
    if sys.argv[1]== 'mesoLR-3T':
        sys.path.insert(1,'/home/tieos/work_cefe_swp-smp/melvin/thesis/code/functions')
        pathData = '/home/tieos/work_cefe_swp-smp/melvin/thesis/'
        pathLLH = '/lustre/tieos/work_cefe_swp-smp/melvin/thesis/'
    elif sys.argv[1] == 'sonia':
        pathData =  '/media/sonia/DATA/data_nico/'

import sparsenesslib.high_level as hl
import sparsenesslib.metrics as metrics
import sparsenesslib.plots as plots
#####################################################################################
#SETTINGS:
#####################################################################################
PIL.Image.MAX_IMAGE_PIXELS = 30001515195151997
478940           

model_name = 'VGG16'  # 'vgg16, resnet (...)'
#weights = 'vggface' #'imagenet','vggface'
list_weights = ['imagenet'] #['vggface','imagenet','vggplace']
#computer = 'LINUX-ES03' #no need to change that unless it's sonia's pc, that infamous thing; in which case, put 'sonia' in parameter.
freqmod = 100 #frequency of prints, if 5: print for 1/5 images
AllPC=[]

pathModel = ""
list_bdd = ""
method = ""
if len(sys.argv) >3:
    list_bdd = sys.argv[2].split(",")
    method = sys.argv[3]
else:
    #'CFD','SCUT-FBP','MART','JEN','SMALLTEST','BIGTEST'
    list_bdd = [ 'CFD_AF','CFD_F'] #"['CFD','MART','JEN','SCUT-FBP','SMALLTEST','BIGTEST']"
    list_bdd = ['MART']
    list_bdd = ['CFD_WM']

    
    #method = "FeatureMap"
    #method = "max"#_FeatureMap"
    method = "pca"
    method = "average"#_FeatureMap"
if len(sys.argv) >4:
    pathModel = sys.argv[4]
#####################################################################################
#CODE
#####################################################################################
list_metrics = ['acp']


k = 1
l = len(list_bdd)*len(list_weights)*len(list_metrics)
for bdd in list_bdd:
    for weight in list_weights:
        _, layers, _ = hl.configModel(model_name, weight)
        for metric in list_metrics:
            print('###########################--COMPUTATION--#################################_STEP: ',k,'/',l,'  ',bdd,', ',weight,', ',metric)
            print(pathData)
            #path = "../../results"+"/"+bdd+"/"+"pcaBlock"+"/"+"pca_values_"+"block1"+".csv";
           # path = "../../results"+"/"+bdd+"/"+"pca"+"/"+"pca_values_"+"block1_conv1"+".csv";
            path = pathData+"/results"+"/"+bdd;
            if pathLLH !="":
                pathLLH =pathLLH+"/results"+"/"+bdd;
            #pathLabel = "../../data/redesigned/"+bdd+"/labels_"+bdd+".csv"
            #pathModel = pathData+"/results/Fairface/pca_FeatureMap"
            #pathModel = pathData+"/results/Fairface_AF/average"
            
            #x = metrics.readCsv(path)
           # metrics.getMultigaussian(x,name =  bdd+" "+"pcaBlock"+" "+"block1")
            #metrics.getMultigaussian(x, name = bdd+" "+"pcaBlock"+" "+"block1_conv1")
            
            #hl.eachFileCSV(path,["pca_values_",layers,".csv"], [pathData,bdd,'_'])
            if method == 'FeatureMap':
                AllPC.append(hl.eachFileCSV(path,["pca_values_",layers,".csv"], writeLLH = True, pathModel =pathModel, method= method, pathLLH = pathLLH))
            else:
                AllPC.append(hl.eachFileCSV(path,[method+"_values_",layers,".csv"], writeLLH = True, pathModel =pathModel, method= method,  pathLLH = pathLLH))
            
            k += 1
#            path = "../../results"+"/"+bdd+"\histo"
#            hl.eachFilePlot(path);
           
        #plots.plotPC(AllPC, list_bdd, layers)
#####################################################################################
import main_LLH 