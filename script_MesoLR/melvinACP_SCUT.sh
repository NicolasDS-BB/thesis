#!/bin/bash
#
#SBATCH -N 1
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --time=999:00:00
#SBATCH --partition=muse-smp
#SBATCH --account=cefe_swp-smp


echo "Running Average Melvin"
if [ $# -lt 2 ]
  then
    
    echo "No arguments supplied"
    python3 /home/tieos/work_cefe_swp-smp/melvin/thesis/code/pre_trained_models/main_pca.py mesoLR-3T
  else
   echo "arguments: $1 , $2"
   python3 /home/tieos/work_cefe_swp-smp/melvin/thesis/code/pre_trained_models/main_pca.py mesoLR-3T $1 $2
fi