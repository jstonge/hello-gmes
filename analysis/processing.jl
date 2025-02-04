using Pkg; Pkg.activate(".");
using DataFrames, CSV, ProgressMeter, ArgParse, Parquet
using Pipe: @pipe
using Parquet2: writefile

function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table! s begin
      "--input", "-i"
      default = "."
      help = "Directory containing the txt files."
    end
  @add_arg_table! s begin
      "--output", "-o"
      default = "."
      help = "Directory containing the txt files."
    end
  @add_arg_table! s begin
      "--csv"
      default = true
    end

  return parse_args(s)
end

"""
Combine all sols and proportion in `sourcesink_output/`, using only unique value, into a parquet file.
"""
function main()
  args = parse_commandline()
  
  DATA_DIR = args["input"]
  fnames = filter(x -> endswith(x, "txt"),  readdir(DATA_DIR, join=true))
  
  @assert length(fnames) > 0 println("There are no data files at the given directory")

  modelname = @pipe fnames[1] |> split(_, "_")[1] |> split(_, "/")[end]

  out_f = "$(modelname).parquet"
  lookup_f = "$(modelname)_lookup.parquet"

  println("Processing files")
  tot_rows = 0
  dfs = []
  p = ProgressMeter.Progress(length(fnames))
  @showprogress for i=eachindex(fnames)
  # Threads.@threads for i=eachindex(fnames)
    fname = fnames[i]

    p_str = @pipe split(fname, "/")[end] |> 
      split(_, "_")[2:end] |> 
      join(_, "_") |>
      replace(_, ".txt" => "")
  
    sol = CSV.read(fname, DataFrame; header=["timestep", "L", "value"], 
                   types=Dict(:timestep => Int, :L => Int, :value => Float32))

    gd = groupby(sol, [:timestep, :L])
    n = nrow(gd[1])
    
    # process functions
    processing(x, n) = round(sum((collect(0:(n-1)) / n) .* x) / sum(x), digits=7)

    df_agg = combine(gd, :value => (x -> round(sum(x), digits=7)) => :value_prop, 
                         :value => (x -> iszero(sum(x)) ? 0.0 : processing(x,n)) => :value)
  
    # Take timestep maxmin so all levels have same length
    minmax_timestep = @pipe df_agg |>
      unique(_, :value) |>
      groupby(_, :L) |>
      combine(_,:timestep => maximum=> :timestep)[!, :timestep] |>
      minimum(_)

    df_agg = filter(:timestep => x -> x < minmax_timestep, df_agg)

    df_agg[!, :name] .= p_str

    push!(dfs, df_agg)
    tot_rows += nrow(df_agg)
    ProgressMeter.next!(p)
  end
  
  println("Concatenating $(tot_rows) rows")
  all_dfs = vcat(dfs...)

  println("Write lookup")
  # Write lookup for rowids -> all_dfs.name to disk
  names_params = unique(all_dfs.name)
  row_ids = Int32.(1:length(names_params))

  # lookup
  println("Converting data to better types")
  lookup_name = Dict()
  [get!(lookup_name, n, row_id) for (n, row_id) in zip(names_params, row_ids)];

  # Write output to disk
  all_dfs.row_id = [lookup_name[n] for n in all_dfs.name]
  
  select!(all_dfs, Not(:name))
  
  all_dfs.L = all_dfs.L
  
  all_dfs.timestep = Int32.(all_dfs.timestep)
  all_dfs.value = round.(all_dfs.value, digits=4)
  all_dfs.value_prop = round.(all_dfs.value_prop, digits=4)

  println("Writing data to disk")
  
  # write lookup file
  write_parquet(joinpath(args["output"], lookup_f), (row_id=row_ids, param_str=names_params))
  # write data file
  write_parquet(joinpath(args["output"], out_f), all_dfs)
end

main()
