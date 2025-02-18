using Pkg; Pkg.activate(".")
using OrdinaryDiffEq: ODESolution
using Plots
using InstitutionalDynamics: run_source_sink2

# Check help for details, e.g.
# julia> ?
# help?> dynamics!

"""
  parse_sol(s)
  ============
  
  Return two dictionaries with level as keys with; (i) prevalence of 
  infected people in that level and (ii) the proportion of institution
  of that level as values.
"""
function parse_sol(s::ODESolution)
    L = length(s.u[1].x)
    tmax = length(s)
    inst_level_prev = Dict()
    inst_level_prop = Dict()
    for ℓ = 1:L
      values_prev = []
      values_prop = []
      for t = 1:tmax
        n = length(s.u[t].x[ℓ])
        x = s.u[t].x[ℓ] # distribution of group states at that level 
        out = sum((collect(0:(n-1)) / (n-1)) .* x) / sum(x) 
        push!(values_prev, out)
        out = sum(x)
        push!(values_prop, out)
      end
      inst_level_prev[ℓ] = values_prev
      inst_level_prop[ℓ] = values_prop
    end
    return inst_level_prev, inst_level_prop
end

L = 4
t_max = 20000
lvl_1 = true
p₀ = 0.0001
β, ξ, α, γ, ρ, η, b, c, μ = 0.13, 1, 1, 1., 0.05, 0.5, 1., 1., 0.0001
p = [β, ξ, α, γ, ρ, η, b, c, μ]
sol = run_source_sink2(p, L=L, t_max=t_max, lvl_1=lvl_1)
res_prev, res_prop = parse_sol(sol)
global_freq = [sum([res_prev[ℓ][t]*res_prop[ℓ][t] for ℓ in 1:L]) for t in 1:t_max]

# plot prevalences
plot(1:t_max, [res_prev[l][1:t_max] for l=1:L], xlabel= "time", ylabel = "prevalence", labels = " " .* string.([1:L;]'),
      width = 3., palette = palette(:Reds)[[3;5;7;9]], xticks = 10 .^ [0,1,2,3,4], xscale=:log10,
      ylims = [0,1.02*maximum([res_prev[l][1:t_max] for l=1:L][1])], legend=:topleft);
plot!(1:t_max, global_freq[1:t_max], width = 2.5, color =:black, ls =:dot, label = "global")
# plot levels' proportions
plot(1:t_max, [res_prop[l][1:t_max] for l=1:L], xlabel= "time", ylabel = "level proportion", labels = " " .* string.([1:L;]'),
      width = 3., palette = palette(:Blues)[[3;5;7;9]], xticks = 10 .^ [0,1,2,3,4], xscale=:log10,
      ylims = [0,1], legend=:topright)