---
theme: dashboard
title: Call-for-action
toc: false
sql:
  sourcesink: ./data/sourcesink2.parquet
  sourcesink_lookup: ./data/sourcesink2_lookup.parquet
---

# Paradoxes in the co-evolution of contagions and institutions
## Exploring the co-evolutionary dynamics between epidemic spreading and institutional adaptation [(J. St-Onge, G. Burgio, _et al_, 2024)](https://arxiv.org/abs/2310.03672).

```js
const r2 = view(Inputs.form({
  x: Inputs.radio(ax_vars2, {label: "x", value: ax_vars2[0]}),
  y: Inputs.radio(ax_vars2, {label: "y", value: ax_vars2[1]})
}))
```

<div class="card">
  <div class="grid grid-cols-2">
    <div class="card">${resize((width) => plot_time_evo(false, { width }))}</div>
    <div class="card">${resize((width) => plot_time_evo(true, { width }))}</div>
  </div>
  <div class="grid grid-cols-2">
    <div class="card">${resize((width) => phase_diagram_facetted( { width }))}</div>
    <div class="card">${resize((width) => phase_diagram( { width }))}</div>
  </div>
</div>


```js
const s2 = view(Inputs.form({
  ax0: Inputs.range(p2[ax_vars2[0]]['minmax'], {step: p2[ax_vars2[0]]['s'], label: `${ax_vars2[0]} (Spreading rate)`, value: .16}),
  ax1: Inputs.range(p2[ax_vars2[1]]['minmax'], {step: p2[ax_vars2[1]]['s'], label: `${ax_vars2[1]} (Between group spread)`}),
  ax2: Inputs.range(p2[ax_vars2[2]]['minmax'], {step: p2[ax_vars2[2]]['s'], label: `${ax_vars2[2]} (Copying rate)`}),
  fp0: Inputs.range(p2[fp2[0]]['minmax'], {step: p2[fp2[0]]['s'], label: `${fp2[0]} (Simple-complex)`, value: p2[fp2[0]]['first_val']}),
  fp1: Inputs.range(p2[fy2]['minmax'], {step: p2[fy2]['s'], label: `${fy2} (Neg. benefits)`, value: p2[fy2]['first_val']}),
  fp2: Inputs.range(p2[fp2[2]]['minmax'], {step: p2[fp2[2]]['s'], label: `${fp2[2]} (Recovery rate)`, value: p2[fp2[2]]['first_val']}),
  fp3: Inputs.range(p2[fp2[3]]['minmax'], {step: p2[fp2[3]]['s'], label: `${fp2[3]} (Group benefits)`, value: -1}),
  fp4: Inputs.range(p2[fp2[4]]['minmax'], {step: p2[fp2[4]]['s'], label: `${fp2[4]} (Inst. Cost)`, value: p2[fp2[4]]['first_val']}),
  fp5: Inputs.range(p2[fp2[5]]['minmax'], {step: p2[fp2[5]]['s'], label: fp2[5], value: p2[fp2[5]]['first_val']}),
}))
```

#### Decomposing the call for action

In construction 🚧

```js
const select = view(Inputs.select(["ρ", "β"], {label: "x-axis", value: "β"}))
```

<div>
  <div style="display: flex">
    <div>${extra2()}</div>
    <div>${extra1(0.005, "purples")}</div>
    <div>${extra1(0.05, "blues")}</div>
  </div>
</div>

```js
const s2b = view(Inputs.form({
  ax0: Inputs.range(p2[ax_vars2[0]]['minmax'], {step: p2[ax_vars2[0]]['s'], label: `${ax_vars2[0]} (Spreading rate)`, disabled: select == "ρ" ? false : true}),
  ax1: Inputs.range(p2[ax_vars2[1]]['minmax'], {step: p2[ax_vars2[1]]['s'], label: `${ax_vars2[1]}`, disabled: select == "ρ" ? true : false}),
  ax2: Inputs.range(p2[ax_vars2[2]]['minmax'], {step: p2[ax_vars2[2]]['s'], label: ax_vars2[2], disabled: true}),
  fp0: Inputs.range(p2[fp2[0]]['minmax'], {step: p2[fp2[0]]['s'], label: fp2[0], value: p2[fp2[0]]['first_val'], disabled: true}),
  fp1: Inputs.range(p2[fy2]['minmax'], {step: p2[fy2]['s'], label: fy2, value: p2[fy2]['first_val'], disabled: true}),
  fp2: Inputs.range(p2[fp2[2]]['minmax'], {step: p2[fp2[2]]['s'], label: fp2[2], value: p2[fp2[2]]['first_val'], disabled: true}),
  fp3: Inputs.range(p2[fp2[3]]['minmax'], {step: p2[fp2[3]]['s'], label: fp2[3], value: -1}),
  fp4: Inputs.range(p2[fp2[4]]['minmax'], {step: p2[fp2[4]]['s'], label: fp2[4], value: p2[fp2[4]]['first_val'], disabled: true}),
  fp5: Inputs.range(p2[fp2[5]]['minmax'], {step: p2[fp2[5]]['s'], label: fp2[5], value: p2[fp2[5]]['first_val'], disabled: true}),
}))
```

```js
const r2b = { x: select, y: "η" }
```

```js
function extra1(eta, scheme) {
  return Plot.plot({
  height: 350,
  width: 450,
  color: { type: "ordinal", scheme: scheme, range: [0.4, 1]},
  marginBottom: 35,
  marginLeft: 50,
  marks: [
    Plot.axisY({ labelAnchor: "center", label: "equilibrium prevalence", tickSpacing: 80, labelArrow: "none" }),
    Plot.axisX({ labelAnchor: "center", label: select, tickSpacing: 80, labelArrow: "none" }),
    Plot.lineY(data_hm2b.filter(d => d.param2 == eta), {
      x: "param1", y: "value", sort: "param1", stroke: "L", 
      tip: true 
    }),
    Plot.lineY(global_hm(data_hm2b).filter(d => d.param2 == eta), {
      x: "param1", y: "value", sort: "param1", stroke: "black", 
      strokeDasharray: "5,3"
    }),
    Plot.frame()
  ]
})
}
```

```js
function extra2() {
 return Plot.plot({
  height: 350,
  width: 450,
  marginBottom: 35,
  marginLeft: 50,
  marks: [
    Plot.ruleY([0]),
    Plot.axisY({ labelAnchor: "center", label: "equilibrium prevalence", tickSpacing: 80, labelArrow: "none" }),
    Plot.axisX({ labelAnchor: "center", label: select, tickSpacing: 80, labelArrow: "none" }),
    Plot.lineY(global_hm(data_hm2b).filter(d => d.param2 == 0.005), {
      x: "param1", y: "value", sort: "param1", stroke: "purple", 
      title: d => `η = 0.005`, 
      tip: true 
    }),
    Plot.lineY(global_hm(data_hm2b).filter(d => d.param2 == 0.05), { 
      x: "param1", y: "value", sort: "param1", stroke: "blue", 
      title: d => `η = 0.05`, tip: true 
    }),
    Plot.frame()
  ]
}) 
}
```

```js
const data_hm2b = get_data_heatmap(data2b, lookup2, fp2, ax_vars2, r2b, s2b, fy2)
```

## How do I interpret the quadrant?

Consider the following

- The upper left quadrant represents the time evolution of the average number of people infected by institution level. The dotted line is the global average, here converging to about 41% of people being infected.
- The upper right quadrant is the proportion of institutions of that strength. We see that 43.6% of institutions converged onto level two. Institutions weren't willing to pay the cost and invest stronger institutions than level 4 in this case.
- The bottom left figure is basically the same plot than upper right, but this is a phase diagram to know how institutional proportional change as a function of relevant parameters in the model, here rho and beta. We can see the phenomenon of what we call **parameter localization**, where some institutional regimes take over part of the parameter space.
- Finally, bottom right figure is the equivalent for the upper left figure, i.e. the global average of infected people over all regimes. This figure let us see how did the institutions perform for any combination of the parameter on the axes. 



<!-- APPENDIX -->


<!-- 1.LOOKUP DATA -->


```sql id=[...sourcesink2_lookup] 
SELECT param_str::STRING as name, row_id FROM sourcesink_lookup
```

```js
const sourcesink2_lookup_map = sourcesink2_lookup.reduce(function(map, obj) {
    map[obj.name] = obj.row_id;
    return map;
}, {})
```

```js
const chosen_row_id = sourcesink2_lookup_map[`${f(s2['ax0'])}_${f(s2['fp0'])}_${f(s2['fp1'])}_${f(s2['fp2'])}_${f(s2['ax1'])}_${f(s2['ax2'])}_${f(s2['fp3'])}_${f(s2['fp4'])}_${f(s2['fp5'])}`]
```
<!-- 2. DATA TIME EVO -->

```sql id=[...data2]
SELECT timestep::INT as timestep, L::INT as L, value, value_prop
FROM sourcesink
WHERE
row_id = ${chosen_row_id}
```

<!-- DATA PHASE DIAGRAMS -->


```sql id=[...data2b]
WITH tmp as (
    SELECT row_id, L, MAX(timestep::INT) as timestep
    FROM sourcesink
    GROUP BY row_id, L
)
SELECT s.value, s.L::INT as L, s.value_prop, ss.param_str::STRING as name
FROM sourcesink s
JOIN tmp
ON s.row_id = tmp.row_id AND s.L = tmp.L AND s.timestep = tmp.timestep
JOIN sourcesink_lookup ss
ON s.row_id = ss.row_id
ORDER BY (s.row_id, s.L)
```

<!-- DATA HEATMAP -->


```js
const data_hm2 = get_data_heatmap(data2b, lookup2, fp2, ax_vars2, r2, s2, fy2)
```

<!-- OTHER CONSTANTS -->

```js
const lookup2 = {}
lookup2['idx2name'] = {0: 'β', 1: 'ξ', 2: 'α', 3: 'γ', 4: 'ρ', 5: 'η', 6: 'b', 7: 'c', 8:'μ'}
lookup2['name2idx'] = {'β': 0, 'ξ': 1, 'α': 2, 'γ': 3, 'ρ': 4, 'η': 5, 'b': 6, 'c': 7, 'μ': 8}
```

```js
const p2 = get_param_table(sourcesink2_lookup_map, lookup2)
const fy2 = "α"  // choose the facet variable
const fp2 = ["ξ", "α", "γ", "b", "c", "μ"]
const ax_vars2 = ["β", "ρ", "η"] // choose the x,y,z axis, i.e. params to vary
```

```js
// To get heatmap data, we need
//   data: data from resdb join `name` and `L`
//   ax_vars: variables we want as x,y,z
//   fx: variable to facet
//   fp: other vars
//   sliders: set of sliders
function get_data_heatmap(data, lookup, fp, ax_vars, radios, sliders, fx) {
  const dat_hm = [];
  
  for (let i=0; i < data.length; i++) { 
    
    const p_split = data[i].name.split('_')
    
    const vs = {} // dictionary containing all the values of selected parameters 

    // Grab the chosen axis0/x, axis1/y, axis2/z
    const [ax0, ax1, ax2] = ax_vars
    vs[ax0] = parseFloat(p_split[lookup['name2idx'][ax0]])
    vs[ax1] = parseFloat(p_split[lookup['name2idx'][ax1]])
    vs[ax2] = parseFloat(p_split[lookup['name2idx'][ax2]])

    // Grab the Fixed parameters
    for (let i=0; i < fp.length; i++) {
      vs[fp[i]] = parseFloat(p_split[lookup['name2idx'][fp[i]]])
    }
    
    // Grab the radios, which will be 2 of the 3 axis vars. 
    // The other other one we'll be the value of our heatmap.
    // This is where we need to know the actual param_name.
    const p1 = parseFloat(p_split[lookup['name2idx'][radios['x']]])
    const p2 = parseFloat(p_split[lookup['name2idx'][radios['y']]])
    const hm_vals_i = {
      'L': data[i].L,
      'fx' : typeof fx !== undefined ? null : p_split[lookup['name2idx'][fx]], 
      'param1': p1,
      'param2': p2,
      'param_str': `${p1}/${p2}`, // We need a way to groupby (p1,p2) for `global_hm()`
      'value': data[i].value,
      'value_prop': data[i].value_prop
    }

    if (vs[fp[0]] === sliders['fp0'] && vs[fp[1]] === sliders['fp1'] && vs[fp[2]] === sliders['fp2'] && vs[fp[3]] == sliders['fp3'] && vs[fp[4]] == sliders['fp4']) {

        // if ax1 == x && ax2 ==y, then ax0 == z
        if (radios['x'] == ax1 && radios['y'] == ax2 && vs[ax0] == sliders['ax0']) {
             dat_hm.push(hm_vals_i)
        } else if (radios['x'] == ax0 && radios['y'] == ax2 && vs[ax1] == sliders['ax1']) {
             dat_hm.push(hm_vals_i)
        } else if (radios['x'] == ax0 && radios['y'] == ax1 && vs[ax2] == sliders['ax2']) {
             dat_hm.push(hm_vals_i)
        }
    }
  }
  return dat_hm
}
```

```js
function f(x) {
  return Number.isInteger(x) ? x.toPrecision(2) : x
}

function minmax(p, i) {
  return d3.extent(p.map(d => parseFloat(d[i])))
}

// Extract the step from a list of values for a parameter
function s(p,i) { 
    const unique_vals = Array.from(new Set(p.map(d => parseFloat(d[i])))).sort((a,b) => a - b)
    const out = []
    for (let i=1; i < unique_vals.length; i++ ) {
      out.push(+(unique_vals[i]-unique_vals[i-1]).toPrecision(2))
    } // return whatev if length is zero
    return out.length === 0 ? 0.1 : out[0]
}
```

```js
// Param table where each key is a parameter, and values 
// are list of values relevant to 
// model: resdb output for a specific model
// lookup: { [0: param1, 1: param2, ...] }
function get_param_table(model_lookup, param_lookup) {
    
  const p = Object.keys(model_lookup).map(d => d.split("_")) 
  
  const param_table = {}
  const first_line_param = p[0]
  for ( let i=0; i < first_line_param.length; i++ ) {
    param_table[param_lookup['idx2name'][i]] = { 
      's': s(p,i), 'first_val': first_line_param[i], 'minmax': minmax(p,i) 
      }
  }
  return param_table
}
```

```js
// we sum for each parameter string the produc of the frequency value of infected and proportion of institution.
function global_hm(d){
  return d3.flatRollup(d, v => d3.sum(v, d => d.value * d.value_prop), d => d.param_str)
           .map(currentElement => ({
             'param1': parseFloat(currentElement[0].split('/')[0]),
             'param2': parseFloat(currentElement[0].split('/')[1]),
             'value': currentElement[1],
             'L': 1
          }))
}
```

<!-- PLOTTING FUNCTIONS - TO EXPORT AS COMPONENTS -->

```js
function plot_time_evo(is_prop) {
  const global_mean = d3.flatRollup(data2, v => d3.sum(v, d => d.value * d.value_prop), d => d.timestep)

  return Plot.plot({
    width: 600,
    height: 300,
    x: {type: "log"},
    y: { percent: true, grid: true}, 
    color: { 
      scheme: is_prop ? "Blues" : "Reds", 
      type: "ordinal", 
      range: [0.3, 1],
      legend: true 
    },
    marks: [
      Plot.axisY({ 
        labelAnchor: "center", 
        label: is_prop ? "% of institutions of that strength" : "% infected", 
        tickSpacing: 80, labelArrow: "none" 
      }),
      Plot.axisX({ 
        labelAnchor: "center", tickSpacing: 80, labelArrow: "none" 
      }),
      Plot.lineY(global_mean, {
        x: d => d[0], y: d => d[1],
        strokeDasharray: "5,3", opacity: is_prop ? 0. : 1.
        }),
      Plot.lineY(
        data2, {
          x: 'timestep', y: is_prop ? "value_prop" : "value", stroke: "L", tip: true
          })
    ]
  })
}
```

```js
function phase_diagram_facetted() {
  return Plot.plot({
    width: 800,
    height: 313,
    marginLeft: 60,
    color: {
      type: "linear",
      scheme: "Greens"
    },
    fy: { label: "" },
    facet: {  data: data_hm2, x: "L", y: 'fx' },
    marks: [
      Plot.axisY({ 
        labelAnchor: "center", 
        label: r2['y'], 
        tickSpacing: 80, labelArrow: "none" 
      }),
      Plot.axisX({ 
        label: r2['x'],
        labelAnchor: "center", tickSpacing: 80, labelArrow: "none" 
      }),
      Plot.raster(data_hm2, {
        x: "param1",
        y: "param2",
        fill: 'value_prop',
        interpolate: "nearest"
      }),
      Plot.tip(data_hm2, Plot.pointer({
        x: "param1",
        y: "param2",
        title: d => `ρ: ${d.param2}\nβ: ${d.param1}\nInst. of that\nstrength: ${(d.value_prop*100).toFixed(2)}%`
      }))
    ]
  })
}
```

```js
function phase_diagram(x, y, z, pal, w, h) {
  return Plot.plot({
    width: 350,
    height: 303,
    marginTop: 42,
    marginLeft: 60,
    color: {
      type: "linear",
      scheme: 'viridis'
    },
    marks: [
      Plot.axisY({ 
        labelAnchor: "center", 
        label: r2['y'], 
        tickSpacing: 80, labelArrow: "none" 
      }),
      Plot.axisX({ 
        label: r2['x'],
        labelAnchor: "center", tickSpacing: 80, labelArrow: "none" 
      }),
      Plot.raster(global_hm(data_hm2), {
        x: "param1",
        y: "param2",
        fill: 'value',
        interpolate: "nearest",
        tip: true,
        title: d => `ρ: ${d.param2}\nβ: ${d.param1}\nGlobal infection rate: ${(d.value*100).toFixed(2)}%`
      })
    ]
  })
}
```
