---
theme: dashboard
title: Call-for-action
style: ../custom-style.css
toc: false
sql:
  sourcesink: ../data/sourcesink3_sparsified.parquet
  sourcesink_lookup: ../data/sourcesink3_lookup.parquet
---

# Model 3

<div class="warning" label="⚠️ Warning">To keep the visualization light, we "sparsified" the raw output with  <a href="https://github.com/jstonge/hello-gmes/blob/main/.sparsify.py#L5-L9">.sparsify.py#L5-L9</a>. That is, we throw away points where the absolute difference between two time steps is greater than 0.00001. This lead to premature termination of runs and more rough results. That said, the results are  qualitatively the same than with raw data. If you </div>

<!-- DASHBOARD 1 -->

```js
import { plot_time_evo } from "../components/time_evo.js";
import { plot_phase_diagram_facetted } from "../components/phase_diagram_facetted.js";
import { phase_diagram } from "../components/phase_diagram.js";
import { get_param_table, global_hm, get_data_heatmap, f, minmax, s } from "../components/helpers.js";
```

<div>
  <div class="card">
    <div class="grid grid-cols-3">
      <div>Control the axis of the phase diagrams (see below for parameter definition): ${radioInput}</div>
      <div>${ax_formInput}</div>
      <div>${fp_formInput}</div>
    </div>
    <div class="grid grid-cols-2">
      <div>${resize((width) => plot_time_evo(time_evo_data, false, { width,  yaxis: "% cooperators" }))}</div>
      <div>${resize((width) => plot_time_evo(time_evo_data, true, { width }))}</div>
    </div>
    <div class="grid grid-cols-3">
      <div class="grid-colspan-2">${resize((width) => plot_phase_diagram_facetted(data_hm, radio, { width }))}</div>
      <div class="grid-colspan-1">${resize((width) => phase_diagram(data_hm, radio, { width }))}</div>
    </div>
  </div>
</div>



<!-- IMPORT DATA -->

```js
// We first create a lookup table to map index to parameter name
const lookup = {}
lookup['idx2name'] = {0: 'β', 1: 'γ', 2: 'ρ', 3: 'b', 4: 'c', 5: 'μ', 6: 'δ', 7: 'α'}
lookup['name2idx'] = {'β': 0, 'γ': 1, 'ρ': 2, 'b': 3, 'c': 4,  'μ':5, 'δ':6, 'α':7}
```

```js
const p1 = get_param_table(sourcesink_lookup_map, lookup)
const ax_vars = ["β", "γ", "ρ"] // choose the x,y,z axis, i.e. params to vary
const fp1 = ["b", "c", "μ", "δ", "α"]
```

<!-- Load lookup to filter main data -->

```sql id=[...sourcesink_lookup] 
SELECT param_str::STRING as name, row_id FROM sourcesink_lookup
```

```js
const sourcesink_lookup_map = sourcesink_lookup.reduce(function(map, obj) {
    map[obj.name] = obj.row_id;
    return map;
}, {})
```

```js
const chosen_row_id = sourcesink_lookup_map[`${f(ax_form['ax0'])}_${f(ax_form['ax1'])}_${f(ax_form['ax2'])}_${f(fp_form['fp0'])}_${f(fp_form['fp1'])}_${f(fp_form['fp2'])}_${f(fp_form['fp3'])}_${f(fp_form['fp4'])}`]
```

```js
// data_hm.filter(d => d.param2 == 0.18 & d.param1 == 0.05)
let row = phase_diagram_data.find(d => d.name == '0.05_0.18_0.09_0.26_1.0_0.1_1.0_0.15')
```

```js
data_hm.filter(d => d.param2 == 0.18 && d.param1 == 0.05)
```

<!-- filter data time evo plot  -->

```sql id=[...time_evo_data]
SELECT timestep::INT as timestep, L::INT as L, value, value_prop
FROM sourcesink
WHERE
row_id = ${chosen_row_id}
```

<!-- Load heatmap data -->

```sql id=[...phase_diagram_data]
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

```js
// Heatmap-related data
const data_hm = get_data_heatmap(phase_diagram_data, lookup, fp1, ax_vars, radio, ax_form, fp_form)
```

<!-- FORM-RELATED LOGIC -->

```js
// We first need to specify x- and y-axis. Other inputs are conditional on them.
const radioInput = Inputs.form({
  x: Inputs.radio(ax_vars, {label: "x-axis", value: ax_vars[0]}),
  y: Inputs.radio(ax_vars, {label: "y-axis", value: ax_vars[1]})
})

const radio =  Generators.input(radioInput);

const ax_formInput = Inputs.form({
  ax0: Inputs.range(p1[ax_vars[0]]['minmax'], {step: p1[ax_vars[0]]['s'], label: `${ax_vars[0]} (Imitation rate)`}),
  ax1: Inputs.range(p1[ax_vars[1]]['minmax'], {step: p1[ax_vars[1]]['s'], label: `${ax_vars[1]} (Recovery)`}),
  ax2: Inputs.range(p1[ax_vars[2]]['minmax'], {step: p1[ax_vars[2]]['s'], label: `${ax_vars[2]} (Global behavioral)`}),
})

const fp_formInput = Inputs.form({
  fp0: Inputs.range(p1[fp1[0]]['minmax'], {step: p1[fp1[0]]['s'], label: `${fp1[0]} (Group benefits)`, value: p1[fp1[0]]
  ['first_val']}),
  fp1: Inputs.range(p1[fp1[1]]['minmax'], {step: p1[fp1[1]]['s'], label: `${fp1[1]} (Inst. cost)`, value: p1[fp1[1]]
  ['first_val']}),
  fp2: Inputs.range(p1[fp1[2]]['minmax'], {step: p1[fp1[2]]['s'], label: `${fp1[2]} (endogenous inst. change)`, value: p1[fp1[2]]['first_val']}),
  fp3: Inputs.range(p1[fp1[3]]['minmax'], {step: p1[fp1[3]]['s'], label: fp1[3], value: p1[fp1[3]]['first_val']}),
  fp4: Inputs.range(p1[fp1[4]]['minmax'], {step: p1[fp1[4]]['s'], label: `${fp1[4]} (endogenous rate of ind. change)`, value: p1[fp1[4]]['first_val']})
})

const ax_form = Generators.input(ax_formInput)
const fp_form = Generators.input(fp_formInput)
```




