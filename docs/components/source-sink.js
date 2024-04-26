// import * as Plot from "npm:@observablehq/plot";

// export function timeline(events, {width, height} = {}) {
//   return Plot.plot({
//     width,
//     height,
//     marginTop: 30,
//     x: {nice: true, label: null, tickFormat: ""},
//     y: {axis: null},
//     marks: [
//       Plot.ruleX(events, {x: "year", y: "y", markerEnd: "dot", strokeWidth: 2.5}),
//       Plot.ruleY([0]),
//       Plot.text(events, {x: "year", y: "y", text: "name", lineAnchor: "bottom", dy: -10, lineWidth: 10, fontSize: 12})
//     ]
//   });
// }


// function plot_time_evo(is_prop) {
//     const global_mean = d3.rollup(data, v => d3.sum(v, d => d.value * d.value_prop), d => d.timestep)
  
//     return Plot.plot({
//       x: {type:"log"},
//       y: {label: is_prop ? "% of institutions of that strength" : "% cooperators", percent: true}, 
//       width: 600,
//       height: 300,
//       color: { 
//         scheme: is_prop ? "Blues" : "Reds", 
//         type: "ordinal", 
//         range: [0.3, 1],
//         legend: true 
//       },
//       marks: [
//         Plot.lineY(Array.from(global_mean.values()), {
//           strokeDasharray: "5,3", opacity: is_prop ? 0. : 1.
//           }),
//         Plot.lineY(
//           data, {
//             x: 'timestep', y: is_prop ? "value_prop" : "value", stroke: "L", tip: true
//             }),
//         Plot.dot(
//           data, {
//             x: 'timestep', y: is_prop ? "value_prop" : "value", stroke: "L"
//             })
//       ]
//     })
//   }