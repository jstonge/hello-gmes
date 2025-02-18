import * as Plot from "npm:@observablehq/plot";
import { global_hm } from "./helpers.js";

export function phase_diagram(data, radio, {width, tiplab} = {}) {
    return Plot.plot({
        width,
        height: 353,
        marginTop: 42,
        marginLeft: 60,
        color: {
            type: "linear",
            scheme: 'viridis'
        },
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
            Plot.raster(global_hm(data), {
            x: "param1",
            y: "param2",
            fill: 'value',
            interpolate: "nearest",
            tip: true,
            title: d => `${radio['x']}: ${d.param1}\n${radio['y']}: ${d.param2}\nGlobal ${tiplab} rate: ${(d.value*100).toFixed(2)}%`
            })
        ]
        })
  }
