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


.PHONY: single_run

# Note can these results can only be run on the UVM cluster. 
run: populate_param_db get_vacc_scripts run_vacc_scripts process_raw_data_coevo

populate_param_db:
	julia $(SCRIPT_DIR)/source-sink-db.jl -m $(model)

get_vacc_scripts:
	julia src/script2vacc.jl --db "source-sink.db" -m sourcesink$(model) -b 30

run_vacc_scripts:
	for file in $$(ls sourcesink$(model)_output/vacc_script/*.sh); do sbatch $$file; done;

process_raw_data_coevo:
	sbatch --mem 60G --partition short --nodes 1 \
		   --ntasks=20 --time 02:59:59 \
		   --job-name=processing .run_processing.sh sourcesink$(model)_output



################################
#                              #
#        PARAMETER SWEEP       #
#                              #
################################

# Repducing the Paradoxes in the co-evolution of contagions and institutions results
.PHONY: coevo

# Note can these results can only be run on the UVM cluster. 
coevo: populate_param_db get_vacc_scripts run_vacc_scripts process_raw_data_coevo

populate_param_db:
	julia $(SCRIPT_DIR)/source-sink-db.jl -m $(model)

get_vacc_scripts:
	julia src/script2vacc.jl --db "source-sink.db" -m sourcesink$(model) -b 30

run_vacc_scripts:
	for file in $$(ls sourcesink$(model)_output/vacc_script/*.sh); do sbatch $$file; done;

process_raw_data_coevo:
	sbatch --mem 60G --partition short --nodes 1 \
		   --ntasks=20 --time 02:59:59 \
		   --job-name=processing .run_processing.sh sourcesink$(model)_output

# for i in {1..508}; do sbatch sourcesink2_output/vacc_script/combine_folder_$i.sh; done;
# for i in {508..1016}; do sbatch sourcesink2_output/vacc_script/combine_folder_$i.sh; done;
# sh .check_nodes.sh

#########################
#                       #
#        CLEANING       #
#                       #
#########################

clean:
	rm -rf docs/.observablehq/cache
# rm -f sourcesink$(model)_output/* || true
# rm -f sourcesink$(model)_output/vacc_script/* || true
# rm sourcesink$(model).parquet || true
# rm sourcesink$(model)_lookup.parquet || true
# rm -f slurm-* || true