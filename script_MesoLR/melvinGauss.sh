#!/bin/bash
#
#SBATCH -N 1
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --time=999:00:00
#SBATCH --partition=muse-visu

echo "Running Average Melvin"
if [ $# -lt 2 ]
  then
    
    echo "No arguments supplied"
    python3 /home/tieos/work_swp-gpu/melvin/thesis/code/pre_trained_models/main_multiGauss.py mesoLR
  else
	if [ $# -lt 3 ]
	then
	  echo "arguments: $1 , $2"
      python3 /home/tieos/work_swp-gpu/melvin/thesis/code/pre_trained_models/main_multiGauss.py mesoLR $1 $2
	else
	  echo "arguments: $1 , $2, $3"
      python3 /home/tieos/work_swp-gpu/melvin/thesis/code/pre_trained_models/main_multiGauss.py mesoLR $1 $2 $3
	fi
fi

echo "finis !!"