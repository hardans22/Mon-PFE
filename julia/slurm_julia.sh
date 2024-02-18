#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=30:00:00
#SBATCH --output=/dev/null
#SBATCH --partition=optimum

module load julia
module load gurobi
/usr/bin/time -v julia  /home/danhar/Documents/julia/main3_slurm.jl
sleep 60
