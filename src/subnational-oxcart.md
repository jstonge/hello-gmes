---
theme: [dashboard, near-midnight]
toc: false
sql:
    data: ./data/subnational.parquet
    metadata: ./data/metadata.parquet
---

# OxGRT - Subnational level
## Infection - Policies coevolution

In the default plot, the color represents the rate of changes of policies in response to COVID-19. As it gets more blue, more policies are implemented, and the other way around for red. We overlay this color on the number of weekly infection, per million. Increasing the window size `k` will take a difference over longer period of time.
```js
// Choose country
const selectInput_c = Inputs.select(new Set(filteredData.map(d=>d.RegionName)), {sort: true, multiple: 5, value: ['Quebec', 'Vermont']});
const select_c = Generators.input(selectInput_c);

// Choose k window for relative difference in policies
const kInput = Inputs.range([2,4], {label: "k (weeks)", value: 2, step: 1});
const k = Generators.input(kInput)

// Log y-axis
const islogInput = Inputs.toggle({label: "log yaxis", value: true})
const islog = Generators.input(islogInput)


// Do facet
const facetInput = Inputs.toggle({label: "do facet", value: true})
const facet = Generators.input(facetInput)

// Toggle phase space view
const phase_spaceInput = Inputs.toggle({label: "phase space", value: false})
const phase_space = Generators.input(phase_spaceInput)

// Type of cases
const inf_typeInput = Inputs.select(["new_deaths_per_100k","new_cases_per_100k"], {label: "yaxis", step: 1, value: ""})
const inf_type = Generators.input(inf_typeInput)
```

<div class="card grid grid-cols-4">
    <div class="grid-colspan-1">
        ${kInput}
        ${islogInput}
        ${facetInput}
        ${phase_spaceInput}
        ${inf_typeInput}
        <br>
        ${selectInput_c}
    </div>
    <div class="grid-colspan-3">
        ${resize((width) => facet_policy(timeseries, { width }) )}
    </div>
</div>

### Dual view (brush to see the evolution)
On this plot, we do single or pairwise comparison of the coevolution of policies and contagion. Currently selected: ${select_c.join(", ")}. <br>
**${select_c.length > 2 ? "Note that with more than 2 selected countries, things get messy" : ""}**

```js
const window_size = view(Inputs.range([1,4], {label: "window size phase space (week)", step: 1, value: 2}))
```

<div>
${resize((width) => weekly_infected_brushplot({width}))}
</div>
<div class="grid grid-cols-2">
    <div>
        ${resize((width) => phase_space_plot({width}) )}
    </div>
    <div>
        ${resize((width) => policy_plot({width}) )}
    </div>
</div>

```js
const ts0 = timeseries.filter(d => d.RegionName === d3.min(select_c) && new Date(d.Date) > startEndSafe[0] && new Date(d.Date) < startEndSafe[1])

const ts1 = timeseries.filter(d => d.RegionName === d3.max(select_c) && new Date(d.Date) > startEndSafe[0] && new Date(d.Date) < startEndSafe[1])
```

<div class="grid grid-cols-2">
<div>
    <h2>${d3.min(select_c)}</h2>
    <br>
    ${table0Input}
    ${bin_plot(ts0)}
    <small><em>red=mean; blue=median</em></small>
</div>
<div>
    <h2>${d3.max(select_c)}</h2>
    <br>
    ${table1Input}
    ${bin_plot(ts1)}
</div>
</div>

```js
const bin_plot = (data) => {
    const df = Rolling(data)
    const mu = d3.mean(df.map(d=>d.Ratio))
    const median = d3.median(df.map(d=>d.Ratio))
    return  Plot.plot({
        grid: true,
        nice: true,
        x: {domain: [-10,10]},
        marks: [
            Plot.frame(),
            Plot.ruleX([mu], {stroke:"red", strokeWidth: 3}),
            Plot.ruleX([median], {stroke:"blue", strokeWidth: 3, opacity: 1}),
            Plot.ruleX(df, { x: "Ratio", opacity: 0.3 })
        ]
})
} 
```

where y2-y1 / x2-x1 is

```tex
\frac{\text{AvgPolicyValue}_{t+1}-\text{AvgPolicyValue}_{t}}{\text{Contagion}_{t+1}-\text{Contagion}_{t}}
```

Where `Contagion` can be either in terms of deaths or weekly new infections. According to GPT, comparing "2020-05-17" for Canada and France, we have:

- Canada (ratio = -7.07) is possibly acting preemptively or cautiously with stricter measures despite decreasing infections.
- France (ratio = 0.912) is showing a more proportional policy response, adjusting policies at a pace similar to the change in infections.

Interpreting the sign:

- **Positive ratio, both increasing**: The infection rate is rising, and policies are tightening in response.
- **Positive ratio, both decreasing**: The infection rate is decreasing, and policies are relaxing.
- **Negative ratio, policy increasing but infection decreasing**: Policies are becoming stricter despite the infection rate falling, possibly to ensure continued containment.
- **Negative ratio, policy decreasing but infection increasing**: Policies are relaxing while infections are rising, which may indicate a delayed or insufficient policy response

And the magnitude

- When the **ratio is large**, it indicates that a significant change in policy corresponds to a relatively small change in infection rate. This could imply that the policy is being adjusted aggressively, even though the infection rate is not changing much
- When the **ratio is small**, it suggests that the infection rate is changing rapidly compared to the policy adjustments. This could indicate that the policy response is slow or not sufficiently reactive to the infection trends.


```js
/** Moving average with reactive window size*/
function Rolling(data) {
    
    function ma(arr, window_size) {
        return arr.map((_, i, array) => {
            if (i < window_size - 1) return null;  
            return d3.mean(array.slice(i - window_size + 1, i + 1)); 
        }).filter(avg => avg !== null);  
    }
    
    const avgCases = ma(data.map(d => d[inf_type]), window_size);
    const avgPolicies = ma(data.map(d => d.AvgPolicyValue), window_size);
    
    return avgCases.map((avgCase, i) => {
        if (i + window_size >= avgCases.length) return null;

        const caseDiff = avgCases[i + window_size] - avgCases[i];

        return {
            RegionName: data[i + window_size - 1].RegionName,  
            AvgPolicyValue: avgPolicies[i],
            avgCases: avgCases[i],
            dPt: `${avgPolicies[i + window_size]} - ${avgPolicies[i]} (${avgPolicies[i + window_size] - avgPolicies[i]})`,
            dIt: `${avgCases[i + window_size].toFixed(2)} - ${avgCases[i].toFixed(2)} (${avgCases[i + window_size].toFixed(2) - avgCases[i].toFixed()})`,  
            Date: data[i + window_size - 1].Date,  
            Ratio: caseDiff !== 0 ? 
                (avgPolicies[i + window_size] - avgPolicies[i]) / caseDiff : 
                null
        };
    }).filter(d => d !== null);
}
```


```js
const table0Input = Inputs.table(Rolling(ts0), {columns:["Date", "dIt", "dPt", "Ratio"]})
const table0 = Generators.input(table0Input)

const table1Input = Inputs.table(Rolling(ts1), {columns:["Date", "dIt", "dPt", "Ratio"]})
const table1 = Generators.input(table1Input)
```

---



Here's what the world look like, on a given and chosen policy type:

```js
const selectInput = Inputs.select(policyTypes);
const select = Generators.input(selectInput);

const timeInput = Inputs.date({value: "2021-09-21"});
const time = Generators.input(timeInput);
```

<div class="grid grid-cols-3">
    <div>
        Choose among policy types
        <br>
        ${selectInput}
        Then choose a day (you can click on date to toggle with keyboard):
        ${timeInput}
    </div>
    <div class="grid-colspan-2">
            ${resize((width) => Plot.plot({
                height: 150,
                width,
                x: {type: "utc"},
                y: {label: "weekly new case (total)"},
                marginLeft: 80,
                marks: [
                    Plot.lineY(metadata, Plot.windowY({k: 7}, {x: "date", y: "new_cases"})),
                    Plot.ruleX([new Date(time)], {stroke: "red"})
                ]
        }))}
    </div>
</div>
<div>${resize((width) =>
Plot.plot({
        width,
        height: width / 2.4,
  projection: "albers-usa",
  color: {
    scheme: "YlGnBu", 
    unknown: "#ccc", 
    label: "Policy Value", legend: true, 
    domain: [0, Policy2ValUS.get(select)],
    range: [0,0.95]
},
  marks: [
     Plot.geo(states, {stroke: "black",
        fill: (map => d => map.get(d.properties.name))(new Map(filteredData.map(d => [d.RegionName, d.PolicyValue]))),
        })
  ]
})
)}
</div>


<br>


```sql id=[...raw_data]
SELECT PolicyType, MAX(PolicyValue) AS PolicyValue
FROM data
WHERE NOT 
    (
        starts_with(PolicyType, 'ConfirmedCases') OR
        starts_with(PolicyType, 'H4') OR
        starts_with(PolicyType, 'H5') OR
        starts_with(PolicyType, 'E4') OR
        starts_with(PolicyType, 'E3') OR
        starts_with(PolicyType, 'V')
    )
GROUP BY PolicyType;
```

```sql id=[...filteredData]
SELECT CountryName, RegionName, PolicyType, PolicyValue 
FROM data 
WHERE 
    PolicyType = ${select}
    AND Date = ${time.toISOString().slice(0, 10)}
```

```sql id=[...metadata]
SELECT 
    MEAN(new_cases_per_100k) as new_cases_per_100k, 
    MEAN(new_deaths_per_100k) as new_deaths_per_100k, 
    date, 
    country,
    RegionName
FROM metadata 
WHERE Jurisdiction = 'STATE_TOTAL'
GROUP BY date, country, RegionName
ORDER BY country, RegionName, date
```

```sql id=[...timeseries]
SELECT 
    d.RegionName, 
    d.Date, 
    COUNT(d.PolicyType)*MEAN(d.PolicyValue) as AvgPolicyValue, 
    SUM(d.PolicyValue) / MEAN(m.new_cases_per_100k) AS NormalizedPolicyValue, 
    MEAN(m.new_cases_per_100k) AS new_cases_per_100k, 
    MEAN(m.new_deaths_per_100k) AS new_deaths_per_100k, 
    SUM(d.PolicyValue) as TotPolicyValue
FROM data as d
LEFT JOIN metadata as m
ON d.RegionName = m.RegionName AND d.Date = m.date
WHERE NOT 
    (
        starts_with(d.PolicyType, 'H4') OR
        starts_with(d.PolicyType, 'H5') OR
        starts_with(d.PolicyType, 'E4') OR
        starts_with(d.PolicyType, 'E3') OR
        starts_with(d.PolicyType, 'V')
    )  AND m.new_cases_per_100k > .1 AND d.Jurisdiction = 'STATE_TOTAL'
GROUP BY d.RegionName, d.Date
ORDER BY d.RegionName, d.Date
```


```sql id=[...UnitedStates]
SELECT PolicyType, MAX(PolicyValue) AS PolicyValue
FROM data
GROUP BY PolicyType;
```

```js
const nation = topojson.feature(us, us.objects.nation)
const states = topojson.feature(us, us.objects.states).features

const policyTypesUS = new Set(UnitedStates.map(d=>d.PolicyType))
const Policy2ValUS = (new Map(UnitedStates.map(d => [d.PolicyType, d.PolicyValue])))
```

```js
const us = FileAttachment("./data/us-counties-10m.json").json()
```

```js
const policyTypes = new Set(raw_data.map(d=>d.PolicyType))
const Policy2Val = (new Map(raw_data.map(d => [d.PolicyType, d.PolicyValue])))
```


<!-- ######################################
     #           PLOTTING FUNCTION        #
     ###################################### -->

<!-- PLOT 1 - FACETTED POLICY PLOT -->

```js
function facet_policy(data, {width} = {}) {
    return Plot.plot((() => {
    const ts = data.filter(d => select_c.includes(d.RegionName))
    const n = select_c.length >= 6 ? 3 : select_c.length <= 3 ? 1 : 2; 
    const keys = Array.from(d3.union(ts.map((d) => d.RegionName)));
    const index = new Map(keys.map((key, i) => [key, i]));
    const fx = (key) => index.get(key) % n;
    const fy = (key) => Math.floor(index.get(key) / n);
    return {
        inset: 10,
        width,
        height: 700,
        fy: {label: null},
        fx: {padding: 0.03},
        color: {
            legend: true, 
            scheme: phase_space ? "Viridis" : "RdYlBu", 
            type: phase_space ? "utc" : "linear",
            domain: phase_space ? d3.extent(data, d => d.Date) : [-3, 3], 
            range: [0.1, 0.9], // So the color is not too dark in dark-theme
            label: phase_space ? "Date":  `Δ Policy Value (k=${k})`
        },
        x: {
            label: phase_space ? "Normalized Policy Value" : "Time", 
            type: phase_space ? "linear" : "utc",
            grid: true
            },
        y: {
            insetTop: 10,
            label: inf_type, 
            grid: true, 
            tickFormat: islog ? "," : "~s",
            type: islog ? "log" : "linear"
        },
        marks: [
            facet ? Plot.frame() : null,
            facet ? 
                Plot.text(keys, {fx, fy, frameAnchor: "top-left", dx: 6, dy: 6}) :
                Plot.text(ts,
                    Plot.selectLast(
                        {
                            x: "Date",
                            y: inf_type, 
                            z: "RegionName",
                            text: "RegionName",
                            dx: 30
                        })),
            phase_space ? 
                Plot.line(ts, 
                    { 
                        filter: (d,i) => i % k === 0,
                        x: "AvgPolicyValue", 
                        y: inf_type, 
                        z: "RegionName", 
                        curve: "catmull-rom", 
                        stroke: "Date", 
                        marker: "arrow", 
                        fy: d => facet ? fy(d.RegionName) : null,
                        fx: d => facet ? fx(d.RegionName) : null,
                        tip: true
                        }
                ) : 
                Plot.line(ts,
                    Plot.map(
                        {stroke: Plot.window({k, reduce: "difference"})},
                        {
                            x: "Date",
                            y: inf_type, 
                            z: "RegionName", 
                            stroke: "AvgPolicyValue", 
                            curve: "catmull-rom", 
                            marker: "none",
                            fy: d => facet ? fy(d.RegionName) : null,
                            fx: d => facet ? fx(d.RegionName) : null,
                            strokeWidth: 2,
                            tip: true
                        }))
        ]
    };
})())
}
```

<!-- PLOT 2 - BRUSH PLOT OF WEEKLY INFECTED TIMESERIES -->

```js
const startEnd = Mutable(null);
const setStartEnd = (se) => startEnd.value = se;
```

```js
const startEndSafe = startEnd === undefined || startEnd === null ? [new Date("2020-03-01"), new Date("2020-09-01")] : startEnd
```

```js
function weekly_infected_brushplot({width} = {}) {
    const data_f = metadata.filter(d => select_c.includes(d.RegionName))
    return Plot.plot({
                height: 200,
                width,
                grid:true,
                x: {type: "utc"},
                y: {
                    label: inf_type, 
                    type: islog ? "log" : "linear", 
                    tickFormat: islog ? "," : "~s"
                    },
                color: {legend: true},
                marginLeft: 80,
                marks: [
                    Plot.lineY(
                        data_f, 
                        Plot.windowY(
                            { k: window_size }, 
                            { x: "date", y: inf_type, stroke: "RegionName" })
                        ),
                        (index, scales, channels, dimensions, context) => {
                    const x1 = dimensions.marginLeft;
                    const x2 = dimensions.width - dimensions.marginRight;
                    const y1 = 0;
                    const y2 = dimensions.height;
                    const brushed = (event) => setStartEnd(event.selection?.map(scales.x.invert));
                    const brush = d3.brushX().extent([[x1, y1], [x2, y2]]).on("brush end", brushed);
                    return d3.create("svg:g").call(brush).node();
                    }
                ]
            })

}
```

```js
function phase_space_plot({width}={}) {

    // Filter based on brush
    const ts = Rolling(timeseries).filter(d => select_c.includes(d.RegionName) && new Date(d.Date) >= startEndSafe[0] && new Date(d.Date) <= startEndSafe[1])

    const line_mark = (region, stroke) => Plot.line(ts, 
                    { 
                        // less than ideal, we filter out point instead of taking the moving average
                        filter: (d,i) => d.RegionName == region,
                        x: "AvgPolicyValue", 
                        y: "avgCases", 
                        z: "RegionName", 
                        curve: "catmull-rom", 
                        stroke, 
                        marker: "arrow", 
                        tip: true
                        }
                )

    const text_mark = () => Plot.text(ts,
                {
                    filter: (d,i) => i % 60 === 0,
                    x: "AvgPolicyValue", 
                    y: "avgCases", 
                    z: "RegionName", 
                    text: "Date",
                    dy: -6,
                    lineAnchor: "bottom"
                }
            )

    return Plot.plot({
        width,
        height: 600,
        color: {
            legend: true, 
            type: "utc",
            scheme: select_c.length === 1 ? "Viridis" : null,
            domain: d3.extent(ts, d => d.Date), 
            range: [0.1, 0.9],
            label: "Date"
        },
        x: { label:"Normalized Policy Value", grid: true },
        y: {
            insetTop: 10,
            label: inf_type, 
            grid: true, 
            tickFormat: islog ? "," : "~s",
            type: islog ? "log" : "linear"
        },
        marks: 
        select_c.length == 1 ?
            [
                line_mark(d3.min(select_c, d=>d), "Date"),
                text_mark()
            ] :
            [
                line_mark(d3.max(select_c, d=>d), "orange"),
                line_mark(d3.min(select_c, d=>d), "#6495ED"),
                text_mark()
            ]
    })
}
```

```js
function policy_plot({width}={}) {

    const ts = Rolling(timeseries).filter(d => 
        select_c.includes(d.RegionName) && new Date(d.Date) >= startEndSafe[0] && new Date(d.Date) <= startEndSafe[1])
    return Plot.plot({
        width,
        height: 600,
        color: {
            legend: true, 
            scheme: "RdYlBu", 
            type: "linear",
            domain: [-3, 3], 
            range: [0.1, 0.9], 
            label: `Δ Policy Value (k=${k})`
        },
        x: {
            label: "Time", 
            type: "utc",
            grid: true
            },
        y: {
            insetTop: 10,
            label: inf_type, 
            grid: true, 
            tickFormat: islog ? "," : "~s",
            type: islog ? "log" : "linear"
        },
        marks: [
            Plot.line(ts,
                    Plot.map(
                        {stroke: Plot.window({k, reduce: "difference"})},
                        {
                            x: "Date",
                            y: "avgCases", 
                            z: "RegionName", 
                            stroke: "AvgPolicyValue", 
                            curve: "catmull-rom", 
                            marker: "none",
                            strokeWidth: 2,
                            tip: true
                        })),
            Plot.text(ts,
                    Plot.selectLast(
                        {
                            x: "Date",
                            y: "avgCases", 
                            z: "RegionName",
                            text: "RegionName",
                            dx: 30
                        })),
        ]
    })
}
```

```js
function weekly_infected_plot(data, {width} = {}) {
    const data_f = data.filter(d => select_c.includes(d.RegionName))
    return Plot.plot({
                height: 200,
                width,
                grid:true,
                x: {type: "utc"},
                y: {label: "WeeklyCases/Million", tickFormat: islog ? "," : "~s"},
                marginLeft: 80,
                marks: [
                    Plot.lineY(
                        data_f, 
                        Plot.windowY(
                            {k: 1}, 
                            {x: "date", y: "new_cases_per_100k", stroke: "RegionName"})
                        ),
                    Plot.ruleX([new Date(time)], {stroke: "red"}),
                ]
            })

}
```

