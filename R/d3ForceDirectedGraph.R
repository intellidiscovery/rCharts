FDG = setRefClass('FDG', contains = 'rCharts', methods = list(
  initialize = function(){
    callSuper()
    LIB <<- get_lib("d3_fdg")
    lib <<- "force_directed_graph"
    templates$script <<- '
    <script type="text/javascript">
    function draw{{chartId}}(){
      var params = {{{ chartParams }}}
      var data = params.data
      var w = params.width,
          h = params.height,
          fill = d3.scale.category20();

      var vis = d3.select("#" + params.id)
                  .append("svg:svg")
                    .attr("width", w)
                    .attr("height", h)
                    .attr("pointer-events", "all")
                  .append("svg:g")
                    .call(d3.behavior.zoom().on("zoom", redraw))
                  .append("svg:g");

      vis.append("svg:rect")
         .attr("width", w)
         .attr("height", h)
         .attr("fill", "white");
      
      function redraw() {
        console.log("here", d3.event.translate, d3.event.scale);
        vis.attr("transform",
          "translate(" + d3.event.translate + ")"
          + " scale(" + d3.event.scale + ")");
      }
    
      var draw = function(data) {
        //Toggle stores whether the highlighting is on
        var toggle = 0;
        //Create an array logging what is connected to what
        var linkedByIndex = {};
        for (i = 0; i < data.nodes.length; i++) {
            linkedByIndex[i + "," + i] = 1;
        };
        data.links.forEach(function (d) {
            linkedByIndex[d.source.index + "," + d.target.index] = 1;
        });
        //This function looks up whether a pair are neighbours
        function neighboring(a, b) {
            return linkedByIndex[a.index + "," + b.index];
        }
        function connectedNodes() {
            if (toggle == 0) {
                //Reduce the opacity of all but the neighbouring nodes
                d = d3.select(this).node().__data__;
                node.style("opacity", function (o) {
                    return neighboring(d, o) | neighboring(o, d) ? 1 : 0.1;
                });
                link.style("opacity", function (o) {
                    return d.index==o.source.index | d.index==o.target.index ? 1 : 0.1;
                });
                //Reduce the op
                toggle = 1;
            } else {
                //Put them back to opacity=1
                node.style("opacity", 1);
                link.style("opacity", 1);
                toggle = 0;
            }
        }
        var force = d3.layout.force()
                      .charge(-120)
                      .linkDistance(30)
                      .nodes(data.nodes)
                      .links(data.links)
                      .size([w, h])
                      .start();
    
        var link = vis.selectAll("line.link")
        .data(data.links)
        .enter().append("svg:line")
        .attr("class", "link")
        .style("stroke-width", function(d) { return Math.sqrt(d.value); })
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });
        
        var node = vis.selectAll("circle.node")
                      .data(data.nodes)
                      .enter().append("svg:circle")
                      .attr("class", "node")
                      .attr("cx", function(d) { return d.x; })
                      .attr("cy", function(d) { return d.y; })
                      .attr("r", 5)
                      .style("fill", function(d) { return fill(d.group); })
                      .call(force.drag);
                      //.on("dblclick", connectedNodes);
        
        node.append("svg:title")
        .text(function(d) { return d.name; });
        
        vis.style("opacity", 1e-6)
            .transition()
            .duration(1000)
            .style("opacity", 1);
        
        force.on("tick", function() {
          link.attr("x1", function(d) { return d.source.x; })
              .attr("y1", function(d) { return d.source.y; })
              .attr("x2", function(d) { return d.target.x; })
              .attr("y2", function(d) { return d.target.y; });
          
          node.attr("cx", function(d) { return d.x; })
              .attr("cy", function(d) { return d.y; });
        });
      };
      
      draw(data);

    };
    
    $(document).ready(function(){
    draw{{chartId}}()
    });
    
    </script>'
  },
  getPayload = function(chartId){
    chartParams = RJSONIO:::toJSON(params)
    list(chartParams = chartParams, data=toJSONArray(params[['data']]),
         chartId = chartId, lib = basename(lib), liburl = LIB$url
    )
  }
))
