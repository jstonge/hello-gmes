import * as Plot from "npm:@observablehq/plot";
import { flatRollup, sum } from "npm:d3-array";

export function plot_time_evo(data, is_prop, {width} = {}) {
  const global_mean = flatRollup(data, v => sum(v, d => d.value * d.value_prop), d => d.timestep)

  return Plot.plot({
    width,
    height: 300,
    x: { type: "log" },
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
        data, {
          x: 'timestep', y: is_prop ? "value_prop" : "value", stroke: "L", tip: true
          }),
      Plot.dotY(
        data, {
          x: 'timestep', y: is_prop ? "value_prop" : "value", stroke: "L", tip: true
          }),
      Plot.frame()
    ]
  });
}
