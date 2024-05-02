import { flatRollup, extent, sum } from "npm:d3-array";

export { get_param_table, global_hm, get_data_heatmap, f, minmax, s } ;

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

function global_hm(d){
    return flatRollup(d, v => sum(v, d => d.value * d.value_prop), d => d.param_str)
             .map(currentElement => ({
               'param1': parseFloat(currentElement[0].split('/')[0]),
               'param2': parseFloat(currentElement[0].split('/')[1]),
               'value': currentElement[1],
               'L': 1
            }))
}

// To get heatmap data, we need
//   data: data from resdb join `name` and `L`
//   ax_vars: variables we want as x,y,z
//   fx: variable to facet
//   fp: other vars
//   sliders: set of sliders
function get_data_heatmap(data, lookup, fp, ax_vars, radios, ax_sliders, fp_sliders, fx) {
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

    if (vs[fp[0]] === fp_sliders['fp0'] && vs[fp[1]] === fp_sliders['fp1'] && vs[fp[2]] === fp_sliders['fp2'] && vs[fp[3]] == fp_sliders['fp3'] && vs[fp[4]] == fp_sliders['fp4']) {

      // if ax1 == x && ax2 ==y, then ax0 == z
      if (radios['x'] == ax1 && radios['y'] == ax2 && vs[ax0] == ax_sliders['ax0']) {
           dat_hm.push(hm_vals_i)
      } else if (radios['x'] == ax0 && radios['y'] == ax2 && vs[ax1] == ax_sliders['ax1']) {
           dat_hm.push(hm_vals_i)
      } else if (radios['x'] == ax0 && radios['y'] == ax1 && vs[ax2] == ax_sliders['ax2']) {
           dat_hm.push(hm_vals_i)
      }
    }
  }
  return dat_hm
}

function f(x) {
  return Number.isInteger(x) ? x.toPrecision(2) : x
}

function minmax(p, i) {
  return extent(p.map(d => parseFloat(d[i])))
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