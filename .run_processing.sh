#!/bin/bash
source ~/myconda.sh
module load julia/julia-1.8.5
julia --project=@. src/processing.jl -i $1/ -o docs/data/
# julia --threads 10 src/04_processing.jl -d $1