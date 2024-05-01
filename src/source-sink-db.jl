# using Pkg; Pkg.activate("../../");
using SQLite, ArgParse, DataFrames

function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table! s begin
      "-m"
      arg_type = Int
      help = "Name of the model to generate scripts"
      "-o"
      default = "."
      help = "Name of the model to generate scripts"
    end

  return parse_args(s)
end

function model1()
  SQLite.execute(db, """DROP TABLE IF EXISTS sourcesink1""")
  param_list = []
  for β=0.:0.02:0.22, γ= 0.9:0.1:1.1, ρ=0.1:0.15:0.40, b=0.02:0.02:0.22, c=0.05:0.2:2.0
    μ = 1e-4
    params = (β, γ, ρ, b, c, μ)
    push!(param_list, params)
  end
  df = DataFrame(param_list)
  rename!(df, ["beta", "gamma", "rho", "b", "cost", "mu"])
  SQLite.load!(df, db, "sourcesink1")
end

function model2()
  SQLite.execute(db, """DROP TABLE IF EXISTS sourcesink2""")
  param_list = []
  for β = 0.055:0.015:0.16, ρ = 0.005:0.015:0.095, η = 0.005:0.015:0.5, b = 0.2:0.4:1.4, c = 0.5:0.5:2.0
    ξ, α, γ, μ = 1.0, 1.0, 1.0, 1e-4
    params = (β, ξ, α, γ, ρ, η, b, c, μ)
    push!(param_list, params)
  end
  df = DataFrame(param_list)
  rename!(df, ["beta", "xi", "alpha", "gamma", "rho", "eta", "b", "cost", "mu"])
  SQLite.load!(df, db, "sourcesink2")
end

function model3()
  SQLite.execute(db, """DROP TABLE IF EXISTS sourcesink3""")
  param_list = []
  for β=0.0:0.01:0.15, ρ=0.0:0.01:0.15, b=0.1:0.1:0.3, α=0.0:0.01:0.15
    γ = β
    c, μ, δ = 1., 0.1, 1.
    params = (β, γ, ρ, b, c, μ, δ, α)
    push!(param_list, params)
  end
  df = DataFrame(param_list)
  rename!(df, ["beta", "gamma", "rho", "b", "cost", "mu", "delta", "alpha"])
  SQLite.load!(df, db, "sourcesink3")
end

function main()
  args = parse_commandline()
  global db = SQLite.DB(joinpath(args["o"], "source-sink.db"))
  if args["m"] == 1
    model1()
  elseif args["m"] == 2
    model2()
  elseif args["m"] == 3
    model3()
  end
end

main()
