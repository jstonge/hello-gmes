DATA_DIR=$(realpath ./data)
DATA_DIR_RAW=$(DATA_DIR)/raw
DATA_DIR_CLEAN=$(DATA_DIR)/clean

FRAMEWORK_DIR=$(realpath ./src)
DATA_DIR_OBS=$(FRAMEWORK_DIR)/data

SCRIPT_DIR=./analysis
INST_DYNAMIC_DIR=$(SCRIPT_DIR)/InstitutionalDynamics.jl
RESULT_DIR=$(realpath ./results)
PROCESSED_DIR=$(RESULT_DIR)/processed


################################
#                              #
#        PARAMETER SWEEP       #
#                              #
################################

.PHONY: populate_param vacc_scripts run_vacc_scripts process sparsify

# Create DB containing the parameter combinations
populate_param:
	julia --project=@. $(SCRIPT_DIR)/source-sink-db.jl -m $(model) -o $(RESULT_DIR)

# Turn the parameter combinations into many slurms scripts that can be run in parallel. 
# Command takes `batch` number as input (how many lines in the param DB to run).
vacc_scripts:
	julia --project=@. $(SCRIPT_DIR)/script-2-vacc.jl -i $(RESULT_DIR) -m sourcesink$(model) -b $(batch) -o $(RESULT_DIR)
	ls $(RESULT_DIR)/sourcesink$(model)_output/vacc_script | wc -l

# We send all those files to the server. We need to be careful as the VACC don't like >1000 files at a time.
# Run parts of all the .sh files if > 1000 files, such as:
# 	for i in {1..508}; do sbatch sourcesink3_output/vacc_script/combine_folder_$i.sh; done;
# 	sh .check_nodes.sh
# 	for i in {508..MAX}; do sbatch sourcesink3_output/vacc_script/combine_folder_$i.sh; done;
run_vacc_scripts:
	for file in $$(ls $(RESULT_DIR)/sourcesink$(model)_output/vacc_script/*.sh); do sbatch $$file; done;
# Note that we print any negative values in the results. 
# If output file size (res_*.txt) is non-zero, then there are neg values.
# run `make check_neg` to see which ones.

# We postprocess the data a first time. 
# We are rounding up to 7 digits, and aggregate all the runs into a single file.
process:
	sbatch --mem 60G --partition short --nodes 1 \
		   --ntasks=20 --time 02:59:59 \
		   --job-name=processing .run_processing.sh $(RESULT_DIR)/sourcesink$(model)_output/ $(PROCESSED_DIR)/

# Sometimes the data is too big for front-end, so we remove all the 
# values where the diff between t and t+1 > $(tolerance).
# tolerance=0.0001 usually works well.
sparsify:
	python .sparsify.py -i $(PROCESSED_DIR)/sourcesink$(model).parquet -t $(tolerance)



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
	julia --project=@. $(INST_DYNAMIC_DIR)/src/sourcesink1.jl --beta $(BETA) -g $(GAMMA) -r $(RHO) -b $(B) -c $(COST) -m $(MU)
	mv sourcesink1* tmp/
	julia --project=@. $(SCRIPT_DIR)/processing.jl -i tmp/ -o $(DATA_DIR_OBS)/single_run
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
	julia --project=@. $(INST_DYNAMIC_DIR)/src/sourcesink2.jl --beta $(BETA) --xi $(XI) -a $(ALPHA) -g $(GAMMA) -r $(RHO) -e $(ETA) -b $(B) -c $(COST) -m $(MU)
	mv sourcesink2_* tmp/
	julia --project=@. $(SCRIPT_DIR)/processing.jl -i tmp/ -o $(DATA_DIR_OBS)/single_run
	rm -rf tmp/

#########################
#                       #
#        HELPERS        #
#                       #
#########################

.PHONY: clean-obs clean-sims check_neg

check_neg:
	find $(RESULT_DIR)/sourcesink$(model)_output/ -name 'res*' -type f -size +100c -exec ls -lah {} +

clean-obs:
	rm -rf docs/.observablehq/cache

clean-sims:
	rm -f results/sourcesink$(model)_output/* || true
	rm -f results/sourcesink$(model)_output/vacc_script/* || true
	rm results/processed/sourcesink$(model).parquet || true
	rm results/processed/sourcesink$(model)_lookup.parquet || true
	rm -f slurm-* || true