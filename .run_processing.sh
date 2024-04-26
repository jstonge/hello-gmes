#!/bin/bash
source ~/myconda.sh
module load julia/julia-1.8.5
julia --threads 10 src/04_processing.jl -d $1