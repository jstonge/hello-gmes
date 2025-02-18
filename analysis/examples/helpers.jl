using Plots
using Measures

create_cache() = isdir(".cache") ? nothing : mkdir(".cache")
unzip(a) = map(x->getfield.(a, x), fieldnames(eltype(a)))

function plot_setup()
    default(legendfont = ("Computer modern", 16),
            tickfont = ("Computer modern", 16),
            guidefontsize = 18, markerstrokewidth=0., markersize = 5,
            linewidth=1, framestyle=:axis,
            titlefontsize=12, grid=:none,
            bottom_margin = 0mm, left_margin = 0mm, right_margin = 0mm)
    
    gr(size=(500,400))  
  end