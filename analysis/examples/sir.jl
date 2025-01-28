using OrdinaryDiffEq, RecursiveArrayTools

N, M = 20, 1000000
I = N
G = zeros(I+1, N+1)
u₀ =  ArrayPartition(Tuple([G[n,:] for n=1:N]))
u₀.x[12][13] = 1.0
p = (0.01 , 0.01)

function dynamics!(du, u, p, t)
    # u = u₀
    # group C of size n and i infected individuals
    C, I, N = u, size(u.x,1), size(first(u.x),1)
    μ, β = p
    θ, ϕ, pop, Spop =  zeros(I), zeros(I), zeros(I), zeros(I)
    
    S = ArrayPartition(zeros(N+1))

    # Mean-field coupling 
    # G.x[i] => accessing full row of i infected individuals 
    # θ: avg inf rate over the groups a sus node is member of
    for i in 1:I
        # i=12
        n_infect = collect(0:(N-1))
        pop[i] = sum(β .* C.x[i])
        θ[i] = pop[i] > 0 ? sum(β*(n_infect .- (i-1)) .* C.x[i]) / pop[i] : 0. 
    end
    
    # SIS dynamics
    for m = 1:N
        # m=1
        S.x[m+1] = -m*ϕ[m]*S.x[m] + μ*(p[m] - S.x[m])
    end

    # ϕ: the avg nb of groups to which such a node belongs 
    #    to in addition to the considered group.
    for m = 1:N
        Spop[m] = sum(m .* S.x[m])
        ϕ[i] = pop[m] > 0 ? sum((m-1) .* m .* S.x[m]) / Spop[m] : 0. 
    end

    
    for n = 1:N, i = 1:I
      n_infect, gr_size = i-1, n-1
      
      # exact AMEs
      du.x[n][i] = -μ*n_infect*C.x[n][i] - (gr_size-n_infect)*β*C.x[n][i]
      n_infect > 0 && ( du.x[n][i] += (gr_size-n_infect+1)*β*C.x[n][i-1])
      n_infect < gr_size && ( du.x[n][i] += μ*(n_infect+1)*G.x[n][i+1] )
      
      # state transition due to their membership to other groups
      du.x[n][i] = -(gr_size-n_infect)*ϕ*θ[i]*C.x[n][i]
      n_infect > 0 && ( du.x[n][i] += (gr_size-n_infect+1)*ϕ[i-1]*θ[i-1]*C.x[n][i-1] )

    end
  end