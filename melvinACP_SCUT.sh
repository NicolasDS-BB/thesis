#!/bin/bash
#
#SBATCH -N 1
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --time=999:00:00
#SBATCH --partition=muse-smp

echo "Running ACP Melvin"
python3 /home/tieos/work_swp-gpu/melvin/thesis/code/pre_trained_models/main_pca.py mesoLR
echo "grosminet a mange titi :( "