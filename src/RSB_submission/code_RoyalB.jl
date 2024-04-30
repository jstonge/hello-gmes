using Pkg; Pkg.activate(".")
using Distributions, OrdinaryDiffEq, RecursiveArrayTools

function initial_cond(;n::Int=20, L::Int=4, M::Int=1000000, p::Float64=0.0001, lvl_1::Bool=false)
  G = zeros(L, n+1)

  if lvl_1 # 99% of population at the lowest level
    M /= 10
    for _ in 1:99*M
      i = sum(collect(rand(Binomial(1, p), n))) # how many total infectees?
      G[1, i+1] += 1 # everytime combination [1,i], count +1
    end
    for _ in 1:M
      ℓ = rand(2:L) # pick a level
      i = sum(collect(rand(Binomial(1, p), n))) # how many total infectees?
      G[ℓ, i+1] += 1 # everytime combination [ℓ,i], count +1
    end
    G = G ./ (100*M) # normalized by tot number of groups
    return ArrayPartition(Tuple([G[ℓ,:] for ℓ=1:L])) 
  else # uniform distribution of population across levels
      for _ in 1:M
        ℓ = rand(1:L) # pick a level
        i = sum(collect(rand(Binomial(1, p), n))) # how many total infectees?
        G[ℓ, i+1] += 1 # everytime combination [ℓ,i], count +1
      end
    G = G ./ M # normalized by tot number of groups
    return ArrayPartition(Tuple([G[ℓ,:] for ℓ=1:L]))
  end
end

g(x; ξ=1) = x^ξ # function to choose between linear (ξ = 1) and nonlinear contagion (ξ ≠ 1)

function dynamics!(du, u, p, t)
  G, L, n = u, size(u.x,1), size(first(u.x),1)
  β, ξ, α, γ, ρ, η, b, c, μ = p
  Z, pop, R = zeros(L), zeros(L), 0.

  # Mean-field coupling and fitness values
  for ℓ in 1:L
    n_infect = collect(0:(n-1))
    R += sum(ρ * n_infect .* G.x[ℓ])
    pop[ℓ] = sum(G.x[ℓ])
    Z[ℓ] = pop[ℓ] > 0 ? sum(exp.(-b*n_infect .- c*(ℓ-1)) .* G.x[ℓ])/pop[ℓ] : 0. 
  end
    
  for ℓ = 1:L, i = 1:n
    n_infect, gr_size = i-1, n-1
    # Diffusion
    du.x[ℓ][i] = -γ*n_infect*G.x[ℓ][i] - β*(ℓ^-α)*g(n_infect+R, ξ=ξ)*(gr_size-n_infect)*G.x[ℓ][i]
    n_infect > 0 && ( du.x[ℓ][i] += β*(ℓ^-α)*g(n_infect-1+R, ξ=ξ)*(gr_size-n_infect+1)*G.x[ℓ][i-1])
    n_infect < gr_size && ( du.x[ℓ][i] += γ*(n_infect+1)*G.x[ℓ][i+1] )
    # Selection
    ℓ > 1 && ( du.x[ℓ][i] += η*G.x[ℓ-1][i]*(Z[ℓ] / Z[ℓ-1] + μ) - η*G.x[ℓ][i]*(Z[ℓ-1] / Z[ℓ] + μ) )
    ℓ < L && ( du.x[ℓ][i] += η*G.x[ℓ+1][i]*(Z[ℓ] / Z[ℓ+1] + μ) - η*G.x[ℓ][i]*(Z[ℓ+1] / Z[ℓ] + μ) )
  end
end

function run_dynamics(p; L=L, perc_inf::Float64=p₀, lvl_1::Bool=false)
  n, M = 20, 1000000
  u₀ = initial_cond(n=n, L=L, M=M, p=perc_inf, lvl_1=lvl_1)
  tspan = (1, t_max)
  
  prob = ODEProblem(dynamics!, u₀, tspan, p)
  return solve(prob, Tsit5(), saveat = 1, reltol=1e-8, abstol=1e-8)
end

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
      x = s.u[t].x[ℓ]
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



# try it out!
using Plots

L = 4
t_max = 20000
lvl_1 = true
p₀ = 0.0001
β, ξ, α, γ, ρ, η, b, c, μ = 0.13, 1, 1, 1., 0.05, 0.5, 1., 1., 0.0001
p = [β, ξ, α, γ, ρ, η, b, c, μ]
sol = run_dynamics(p, L=L, lvl_1=lvl_1)
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