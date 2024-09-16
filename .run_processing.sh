#!/bin/bash
source ~/myconda.sh
module load julia/1.10.0
julia --project=@. src/processing.jl -i $1 -o $2