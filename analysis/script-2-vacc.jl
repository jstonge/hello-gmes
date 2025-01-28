# using Pkg; Pkg.activate("../../");
using SQLite, DataFrames, ArgParse

function parse_commandline()
    s = ArgParseSettings()
  
    @add_arg_table! s begin
        "-i"
        help = "Name of the db containing params"
        "-m"
        help = "Name of the model to generate scripts"
        "-b"
        arg_type = Int
        help = "Number of runs by batches"
        "-o"
        default = "."
      end
  
    return parse_args(s)
end

function main()
    args = parse_commandline()

    global batch_size = args["b"]
    global INPUT_DIR = args["i"]
    global MODEL_NAME = args["m"]
    global OUTPUT_DIR = joinpath(args["o"], "$(MODEL_NAME)_output")
    global MODEL_DIR = joinpath("src", "InstitutionalDynamics.jl")
    script_folder = "$(OUTPUT_DIR)/vacc_script"
    
    if isdir("$(OUTPUT_DIR)") == false
        mkdir("$(OUTPUT_DIR)"); mkdir("$(script_folder)") 
    end
    
    db = SQLite.DB(joinpath(INPUT_DIR, "source-sink.db"))
    c = DBInterface.execute(db, """SELECT * from $(MODEL_NAME)""") |> DataFrame

    global mem = "8gb"
    global wall_time = "02:59:59"
    global queue = parse(Int,wall_time[:2]) < 3 ? "short" : "bluemoon"
    global batch_counter = 1
    global OFFSET = 0

    function write2db()
        open(full_script_path, "w") do io
            write(io, "#!/bin/bash\n")
            write(io, "#SBATCH --partition=$(queue)\n")
            write(io, "#SBATCH --nodes=1\n")
            write(io, "#SBATCH --mem=$(mem)\n")
            write(io, "#SBATCH --time=$(wall_time)\n")
            write(io, "#SBATCH --job-name=$(batch_counter)\n")
            write(io, "#SBATCH --output=$(OUTPUT_DIR)/res_$(batch_counter).out \n")
            write(io, "source ~/myconda.sh \n")
            write(io, "module load julia/1.10.0 \n")
            write(io, "julia --project=@. $(MODEL_DIR)/src/$(MODEL_NAME).jl --db $(INPUT_DIR)/source-sink.db -O $(OFFSET) -L $(batch_size) -o $(OUTPUT_DIR)")
        end
    end

    for i=1:nrow(c)
        global full_script_path = "$(script_folder)/combine_folder_$(batch_counter).sh"
        if (i % batch_size) == 0   
            write2db()
            batch_counter += 1
            OFFSET = i
        end
    end
    write2db()
end
  
main()