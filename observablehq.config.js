// See https://observablehq.com/framework/config for documentation.
export default {
  title: "Hello GMEs",
  pages: [
    {name: "getting-started", path: "/getting-started"},
    {
      name: "Models",
      path: "/getting-started",
      pages: [
        {name: "Source Sink", path: "/models/source-sink"},
        {name: "Call For Action", path: "/models/call-for-action"},
        {name: "Model 3", path: "/models/model-3"}
      ]
    },
    {
      name: "Data-Driven",
      path: "/getting-started",
      pages: [
        {name: "OxGRT - Subnational level", path: "/empirical/subnational-oxcart"},
        {name: "OxGRT - National level", path: "/empirical/world-oxcart"},
      ]
    }
  ],
  head: '<link rel="icon" href="observable.png" type="image/png" sizes="32x32">',
  header: ({path}) => `<div style="display: justify-content: flex-end; direction: rtl;"><small><a href="https://github.com/jstonge/hello-gmes/blob/main/src${path}.md?plain=1">view source</a></small></div>`,
  root: "src",
  output: "dist", // path to the output root for build
  // Some additional configuration options and their defaults:
  // footer: "Built with Observable.", // what to show in the footer (HTML)
  // sidebar: true, // whether to show the sidebar
  // toc: true, // whether to show the table of contents
  // pager: true, // whether to show previous & next links in the footer
  // search: true, // activate search
  // linkify: true, // convert URLs in Markdown to links
  // typographer: false, // smart quotes and other typographic improvements
  // cleanUrls: true, // drop .html from URLs
};
