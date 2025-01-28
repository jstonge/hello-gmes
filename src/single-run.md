---
theme: air
title: single-run
toc: false
sql:
  sourcesink1: ./data/single_run/sourcesink1.parquet
  sourcesink_lookup1: ./data/single_run/sourcesink1_lookup.parquet
  sourcesink2: ./data/single_run/sourcesink2.parquet
  sourcesink_lookup2: ./data/single_run/sourcesink2_lookup.parquet
---

# Running single run

```js
import { plot_time_evo } from "./components/time_evo.js";
```

## Source-sink

```sql id=[...lookup1]
SELECT * FROM sourcesink_lookup1
```

```sql id=[...time_evo_data1]
SELECT timestep::INT as timestep, L::INT as L, value, value_prop
FROM sourcesink1
```

```js
const p_str = lookup1[0].param_str.split("_")
```

<div>
      β=${p_str[0]}, α=${p_str[1]}, γ=${p_str[2]}, ρ=${p_str[3]}, b=${p_str[4]}, c=${p_str[5]}, μ=0.0001
      <div class="grid grid-cols-2">
            <div>${resize((width) => plot_time_evo(time_evo_data1, false, { width }))}</div>
            <div>${resize((width) => plot_time_evo(time_evo_data1, true, { width }))}</div>
      </div>
</div>

## Co-evo

```sql id=[...lookup2]
SELECT * FROM sourcesink_lookup2
```

```sql id=[...time_evo_data2]
SELECT timestep::INT as timestep, L::INT as L, value, value_prop
FROM sourcesink2
```

```js
const p_str2 = lookup2[0].param_str.split("_")
```
<div>
      β=${p_str2[0]}, ξ=${p_str2[1]}, α=${p_str2[2]}, γ=${p_str2[3]}, ρ=${p_str2[4]}, ε=${p_str2[5]}, b=${p_str2[6]}, c=${p_str2[7]}, μ=0.0001
      <div class="grid grid-cols-2">
            <div>${resize((width) => plot_time_evo(time_evo_data2, false, { width }))}</div>
            <div>${resize((width) => plot_time_evo(time_evo_data2, true, { width }))}</div>
      </div>
</div>