DATA_DIR=$(realpath ./data)
DATA_DIR_RAW=$(DATA_DIR)/raw
DATA_DIR_CLEAN=$(DATA_DIR)/clean

FRAMEWORK_DIR=$(realpath ./docs)
DATA_DIR_OBS=$(FRAMEWORK_DIR)/data

SCRIPT_DIR=./src


##########################
#                        #
#       SINGLE RUN       #
#                        #
##########################

.PHONY: single-run-source-sink single-run-coevo

BETA=0.07
ALPHA=0.5
GAMMA=1.
RHO=0.1
B=0.18
COST=1.05
MU=1e-4
single-run-source-sink: 
	mkdir -p tmp/
	julia --project=@. src/InstitutionalDynamics.jl/src/sourcesink1.jl --beta $(BETA) -g $(GAMMA) -r $(RHO) -b $(B) -c $(COST) -m $(MU)
	mv sourcesink1* tmp/
	julia --project=@. src/processing.jl -i tmp/ -o docs/data/single_run
	rm -rf tmp/

BETA=0.07
XI=1.
ALPHA=0.5
GAMMA=1.
RHO=0.1
ETA=0.1
B=0.18
COST=1.05
MU=1e-4
single-run-coevo: 
	mkdir -p tmp/
	julia --project=@. src/InstitutionalDynamics.jl/src/sourcesink2.jl --beta $(BETA) --xi $(XI) -a $(ALPHA) -g $(GAMMA) -r $(RHO) -e $(ETA) -b $(B) -c $(COST) -m $(MU)
	mv sourcesink2_* tmp/
	julia --project=@. src/processing.jl -i tmp/ -o docs/data/single_run
	rm -rf tmp/

################################
#                              #
#        PARAMETER SWEEP       #
#                              #
################################

# Repducing the Paradoxes in the co-evolution of contagions and institutions results
.PHONY: run-sim

# Note can these results can only be run on the UVM cluster. 
run-sim: populate_param_db get_vacc_scripts run_vacc_scripts process_raw_data_coevo sparsify

populate_param_db:
	julia $(SCRIPT_DIR)/source-sink-db.jl -m $(model)

get_vacc_scripts:
	julia src/script-2-vacc.jl --db "source-sink.db" -m sourcesink$(model) -b 30

run_vacc_scripts:
	for file in $$(ls sourcesink$(model)_output/vacc_script/*.sh); do sbatch $$file; done;

process_raw_data_coevo:
	sbatch --mem 60G --partition short --nodes 1 \
		   --ntasks=20 --time 02:59:59 \
		   --job-name=processing .run_processing.sh sourcesink$(model)_output

sparsify:
	python .sparsify.py sourcesink$(model)_output

# Run parts of all the .sh files
# for i in {1..508}; do sbatch sourcesink2_output/vacc_script/combine_folder_$i.sh; done;
# sh .check_nodes.sh
# for i in {508..1016}; do sbatch sourcesink2_output/vacc_script/combine_folder_$i.sh; done;

#########################
#                       #
#        CLEANING       #
#                       #
#########################

.PHONY: clean-obs clean-sims

clean-obs:
	rm -rf docs/.observablehq/cache

clean-sims:
	rm -f sourcesink$(model)_output/* || true
	rm -f sourcesink$(model)_output/vacc_script/* || true
	rm sourcesink$(model).parquet || true
	rm sourcesink$(model)_lookup.parquet || true
	rm -f slurm-* || true