import * as Plot from "npm:@observablehq/plot";

export function plot_phase_diagram_facetted(data, radio, { width } = {}) {
    return Plot.plot({
      width,
      height: 363,
      marginLeft: 60,
      color: {
        type: "linear",
        scheme: "Greens"
      },
      fy: { label: "" },
      facet: {  data: data, x: "L", y: 'fx' },
      marks: [
        Plot.axisY({ 
          labelAnchor: "center", 
          label: radio['y'], 
          tickSpacing: 80, labelArrow: "none" 
        }),
        Plot.axisX({ 
          label: radio['x'],
          labelAnchor: "center", tickSpacing: 80, labelArrow: "none" 
        }),
        Plot.raster(data, {
          x: "param1",
          y: "param2",
          fill: 'value_prop',
          interpolate: "nearest"
        }),
        Plot.tip(data, Plot.pointer({
          x: "param1",
          y: "param2",
          title: d => `ρ: ${d.param2}\nβ: ${d.param1}\nInst. of that\nstrength: ${(d.value_prop*100).toFixed(2)}%`
        }))
      ]
    })
  }