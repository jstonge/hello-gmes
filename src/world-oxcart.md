---
theme: [dashboard, near-midnight]
toc: false
sql:
    data: ./data/OxCGRT_compact_national_v1.parquet
    metadata: ./data/metadata.parquet
---

# OxGRT - National level


```js
const selectInput_c = Inputs.select(filteredData.map(d=>d.CountryName), {multiple: 30, value: ["Canada", "Germany", "United Kingdom", "Denmark"]});
const select_c = Generators.input(selectInput_c);

const kInput = Inputs.range([1,60], {label: "window size", value: 7, step: 1});
const k = Generators.input(kInput)

const islogInput = Inputs.toggle({label: "log yaxis", value: true})
const islog = Generators.input(islogInput)

const facetInput = Inputs.toggle({label: "do facet", value: true})
const facet = Generators.input(facetInput)

const phase_spaceInut = Inputs.toggle({label: "phase space", value: false})
const phase_space = Generators.input(phase_spaceInut)
```

<div class="grid grid-cols-4">
    <div class="grid-colspan-1">
        ${kInput}
        ${islogInput}
        ${facetInput}
        <br>
        ${selectInput_c}
    </div>
    <div class="card grid-colspan-3">
        ${resize((width) => facet_policy(timeseries, { width }) )}
    </div>
</div>

<div class="card  grid grid-cols-2">
    <div>
        ${resize((width) => avg_policy_plot(timeseries, {width}))}
    </div>
</div>

Here's what the world look like, on a given and chosen policy type:

```js
const selectInput = Inputs.select(policyTypes);
const select = Generators.input(selectInput);

const timeInput = Inputs.date({value: "2021-09-21"});
const time = Generators.input(timeInput);
```

<div>
    <div class="grid grid-cols-4">
        <div class="grid-colspan-1">
        <br>
            Choose day
            ${timeInput}
            Policy type:
            ${selectInput}
        </div>
        <div class="grid-colspan-3">
            ${resize((width) => weekly_infected_plot(metadata, { width }))}
        </div>
    </div>
    ${resize((width) => world_map({width}))}
</div>


<br>

```sql id=[...raw_data]
SELECT PolicyType, MAX(PolicyValue) AS PolicyValue
FROM data
WHERE NOT 
    (
        starts_with(PolicyType, 'ConfirmedCases') OR
        starts_with(PolicyType, 'E') OR
        starts_with(PolicyType, 'H4') OR
        starts_with(PolicyType, 'H5') OR
        starts_with(PolicyType, 'V')
    )
GROUP BY PolicyType;
```

```sql id=[...filteredData]
SELECT CountryName, PolicyType, PolicyValue 
FROM data 
WHERE 
    PolicyType = ${select}
    AND Date = ${time.toISOString().slice(0, 10)}
```

```sql id=[...metadata]
SELECT 
    MEAN(weekly_cases_per_million) as new_cases, 
    date, 
    country
FROM metadata 
GROUP BY date, country
ORDER BY country, date
```


```sql id=[...timeseries]
SELECT 
    d.CountryName, 
    d.Date, 
    COUNT(d.PolicyType)*MEAN(d.PolicyValue) as AvgPolicyValue, 
    SUM(d.PolicyValue) / MEAN(m.weekly_cases_per_million) AS NormalizedPolicyValue, 
    MEAN(m.weekly_cases_per_million) AS AvgTotCasesPerMillion, 
    SUM(d.PolicyValue) as TotPolicyValue
FROM data as d
LEFT JOIN metadata as m
ON d.CountryName = m.country AND d.Date = m.date
WHERE NOT 
    (
        starts_with(d.PolicyType, 'E') OR
        starts_with(d.PolicyType, 'H4') OR
        starts_with(d.PolicyType, 'H5') OR
        starts_with(d.PolicyType, 'V')
    ) 
GROUP BY d.CountryName, d.Date
ORDER BY d.CountryName, d.Date
```


```js
const world = FileAttachment("./data/countries-50m.json").json()
```

```js
const policyTypes = new Set(raw_data.map(d=>d.PolicyType))
const Policy2Val = (new Map(raw_data.map(d => [d.PolicyType, d.PolicyValue])))

const countries = topojson.feature(world, world.objects.countries)
const countrymesh = topojson.mesh(world, world.objects.countries, (a, b) => a !== b)
```

```js
function weekly_infected_plot(data, {width} = {}) {
    const data_f = data.filter(d => select_c.includes(d.country))
    return Plot.plot({
                height: 200,
                width,
                grid:true,
                x: {type: "utc"},
                y: {label: "WeeklyCases/Million"},
                marginLeft: 80,
                marks: [
                    Plot.lineY(
                        data_f, 
                        Plot.windowY(
                            {k: 1}, 
                            {x: "date", y: "new_cases", stroke: "country"})
                        ),
                    Plot.ruleX([new Date(time)], {stroke: "red"}),
                ]
            })

}
```

```js
function avg_policy_plot(data, {width} = {}) {

    const ts = data.filter(d => select_c.includes(d.CountryName))
    return Plot.plot({
            height: 300,
            width,
            grid:true,
            x: {type: "utc"},
            color: {legend:true},
            marks: [
                Plot.lineY(
                    ts, 
                    Plot.windowY(
                        { k: 1,  reduce: "sum" }, 
                        { x: "Date", y: "AvgPolicyValue", stroke:"CountryName", tip: true })
                        ),
                Plot.ruleX([new Date(time)], {stroke: "red"}),
            ]
        })

}
```

```js
function facet_policy(data, {width} = {}) {
    return Plot.plot((() => {
    const ts = data.filter(d => select_c.includes(d.CountryName))
    const n = select_c.length <= 3 ? 1 : 2; 
    const keys = Array.from(d3.union(ts.map((d) => d.CountryName)));
    const index = new Map(keys.map((key, i) => [key, i]));
    const fx = (key) => index.get(key) % n;
    const fy = (key) => Math.floor(index.get(key) / n);
    return {
        inset: 10,
        width,
        height: 620,
        fy: {label: null},
        fx: {padding: 0.03},
        color: {
            legend: true, 
            scheme: phase_space ? "Viridis" : "RdYlBu", 
            type: phase_space ? "utc" : "linear",
            domain: phase_space ? d3.extent(data, d => d.Date) : [-3, 3], 
            range: [0.1, 0.9], // So the color is not too dark in dark-theme
            label: phase_space ? "Date": "Normalized Difference in Policy Value"
        },
        x: {
            label: phase_space ? "Normalized Policy Value" : "Time", 
            type: phase_space ? "linear" : "utc",
            grid: phase_space
            },
        y: {
            insetTop: 10,
            label: "Weekly cases (per million)", 
            grid: true, 
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
                            y: "AvgTotCasesPerMillion", 
                            z: "CountryName",
                            text: "CountryName",
                            dx: 30
                        })),
            phase_space ? 
                Plot.line(ts, 
                    { 
                        filter: (d,i) => i % k === 0,
                        x: "AvgPolicyValue", 
                        y: "AvgTotCasesPerMillion", 
                        z: "CountryName", 
                        curve: "catmull-rom", 
                        stroke: "Date", 
                        marker: "arrow", 
                        fy: d => facet ? fy(d.CountryName) : null,
                        fx: d => facet ? fx(d.CountryName) : null
                        }
                ) : 
                Plot.line(ts,
                    Plot.map(
                        {stroke: Plot.window({k, reduce: "difference"})},
                        {
                            x: "Date",
                            y: "AvgTotCasesPerMillion", 
                            z: "CountryName", 
                            stroke: "AvgPolicyValue", 
                            curve: "catmull-rom", 
                            marker: "none",
                            fy: d => facet ? fy(d.CountryName) : null,
                            fx: d => facet ? fx(d.CountryName) : null,
                            strokeWidth: 2,
                            tip: true
                        }))
        ]
    };
})())
}
```

```js
function world_map({width}={}) {
    return Plot.plot({
    projection: "equal-earth",
    width,
    height: width / 2.4,
    color: {
        scheme: "YlGnBu", 
        unknown: "#ccc", 
        type: "ordinal",
        label: "Policy Value", 
        legend: true,
        domain: d3.range(Policy2Val.get(select)+1),
        range: [0, 0.9]
    } ,
    marks: [
        Plot.sphere({stroke: "currentColor"}),
        Plot.geo(countries, {
            tip:true,
            title: (d => d.properties.name),
            fill: (map => d => map.get(d.properties.name))(new Map(filteredData.map(d => [d.CountryName, d.PolicyValue])))
        }),
        Plot.geo(countrymesh, {stroke: "black", strokeOpacity: 0.3}),
    ]
    })
}
```



<!-- ### Metadata

```sql
SELECT * FROM metadata
```

I want timeseries of policy values, but somehow normalized by the fraction of people infected on that date and place.

```sql
SELECT 
    d.CountryName, 
    d.Date, 
           SUM(d.PolicyValue) / MEAN(m.weekly_cases_per_million) AS NormalizedPolicyValue, 
    MEAN(m.weekly_cases_per_million) AS AvgTotCasesPerMillion, 
    SUM(d.PolicyValue) as TotPolicyValue
FROM data as d
LEFT JOIN metadata as m
ON d.CountryName = m.country AND d.Date = m.date
WHERE NOT 
    (
        starts_with(d.PolicyType, 'E') OR
        starts_with(d.PolicyType, 'H4') OR
        starts_with(d.PolicyType, 'H5') OR
        starts_with(d.PolicyType, 'V')
    ) AND CountryName = 'Canada'
GROUP BY d.CountryName, d.Date
ORDER BY d.CountryName, d.Date
``` -->