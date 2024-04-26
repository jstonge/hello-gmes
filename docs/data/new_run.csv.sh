# beta=$1
# gamma=$2
mkdir -p tmp/
julia --project=@. src/InstitutionalDynamics.jl/src/sourcesink1.jl --beta 0.27 -g 1.1 
mv sourcesink1_0.27_1.1_0.1_0.18_1.05_0.0001.txt tmp
julia --project=@. src/processing.jl -d tmp/