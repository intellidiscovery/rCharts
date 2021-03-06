TreeDiagram = setRefClass('TreeDiagram', contains = 'rCharts', methods = list(
  initialize = function(){
    callSuper()
    LIB <<- get_lib("d3_tree_diagram")
    lib <<- "tree_diagram"
    templates$script <<- '
    <script type="text/javascript">
    function draw{{chartId}}(){
      var params = {{{ chartParams }}}
      
      // convert data from flat records to nested objects
      var dataMap = params.data.reduce(function(map, node) {
        map[node.name] = node;
        return map;
      }, {});

      var treeData = [];
      params.data.forEach(function(node) {
        // add short name
        node.sname = ((node.name.length>30)&&(/^.*\\sin\\s.*$/.test(node.name)))?node.name.substr(0,25)+"...":node.name;
        // add to parent
        var parent = dataMap[node.parent];
        if (parent) {
          // create child array if it doesn\'t exist
          (parent.children || (parent.children = []))
          // add node to child array
          .push(node);
        } else {
          // parent is null or missing
          treeData.push(node);
        }
      });
    
      var margin = params.margin,
          width = params.width - margin.right - margin.left,
          height = params.height - margin.top - margin.bottom;
    
      var i = 0,
        duration = 750,
        root;

      // Calculate total nodes, max label length
      var totalNodes = 0;
      var maxLabelLength = 0;
      // panning variables
      var panSpeed = 200;
      var panBoundary = 20; // Within 20px from edges will pan when dragging.
    
      var tree = d3.layout.tree()
          .size([height, width]);
      
      var diagonal = d3.svg.diagonal()
          .projection(function(d) { return [d.y, d.x]; });

      // A recursive helper function for performing some setup by walking through all nodes

      function visit(parent, visitFn, childrenFn) {
        if (!parent) return;
        
        visitFn(parent);
        
        var children = childrenFn(parent);
        if (children) {
          var count = children.length;
          for (var i = 0; i < count; i++) {
            visit(children[i], visitFn, childrenFn);
          }
        }
      }
    
      // Call visit function to establish maxLabelLength
      visit(treeData[0], function(d) {
        totalNodes++;
        maxLabelLength = Math.max(d.name.length, maxLabelLength);
      
      }, function(d) {
        return d.children && d.children.length > 0 ? d.children : null;
      });
    
    
      // sort the tree according to the node names
      
      function sortTree() {
      tree.sort(function(a, b) {
      return b.name.toLowerCase() < a.name.toLowerCase() ? 1 : -1;
      });
      }
      // Sort the tree initially incase the JSON isn\'t in a sorted order.
      sortTree();

      function pan(domNode, direction) {
        var speed = panSpeed;
        if (panTimer) {
          clearTimeout(panTimer);
          translateCoords = d3.transform(svgGroup.attr("transform"));
          if (direction == "left" || direction == "right") {
          translateX = direction == "left" ? translateCoords.translate[0] + speed : translateCoords.translate[0] - speed;
          translateY = translateCoords.translate[1];
          } else if (direction == "up" || direction == "down") {
          translateX = translateCoords.translate[0];
          translateY = direction == "up" ? translateCoords.translate[1] + speed : translateCoords.translate[1] - speed;
          }
          scaleX = translateCoords.scale[0];
          scaleY = translateCoords.scale[1];
          scale = zoomListener.scale();
          svgGroup.transition().attr("transform", "translate(" + translateX + "," + translateY + ")scale(" + scale + ")");
          d3.select(domNode).select("g.node").attr("transform", "translate(" + translateX + "," + translateY + ")");
          zoomListener.scale(zoomListener.scale());
          zoomListener.translate([translateX, translateY]);
          panTimer = setTimeout(function() {
          pan(domNode, speed, direction);
          }, 50);
        }
      }
    
      // Define the zoom function for the zoomable tree
      
      function zoom() {
        svgGroup.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
      }
    
    
      // define the zoomListener which calls the zoom function on the "zoom" event constrained within the scaleExtents
      var zoomListener = d3.behavior.zoom().scaleExtent([0.1, 3]).on("zoom", zoom);
      
      var baseSvg = d3.select("#" + params.id).append("svg")
          .attr("width", width + margin.right + margin.left)
          .attr("height", height + margin.top + margin.bottom)
          .attr("class", "overlay")
          .call(zoomListener);
      
      // Append a group which holds all nodes and which the zoom Listener can act upon.
      var svgGroup = baseSvg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");;

      // Define the root
      root = treeData[0];
      root.x0 = height / 2;
      root.y0 = 0;

      // Layout the tree initially and center on the root node.
      update(root);
      //centerNode(root);
    
      // Function to center node when clicked/dropped so node doesn\'t get lost when collapsing/moving with large amount of children.
    
      function centerNode(source) {
        scale = zoomListener.scale();
        x = -source.y0;
        y = -source.x0;
        x = x * scale + width / 2;
        y = y * scale + height / 2;
        d3.select("g").transition()
        .duration(duration)
        .attr("transform", "translate(" + x + "," + y + ")scale(" + scale + ")");
        zoomListener.scale(scale);
        zoomListener.translate([x, y]);
      }
    
      // Toggle children function
      
      function toggleChildren(d) {
        if (d.children) {
          d._children = d.children;
          d.children = null;
        } else if (d._children) {
          d.children = d._children;
          d._children = null;
        }
        return d;
      }
    
      // Toggle children on click.
      
      function click(d) {
        if (d3.event.defaultPrevented) return; // click suppressed
        d = toggleChildren(d);
        update(d);
        centerNode(d);
      }

      // display long name when hovered
      function mouseover(d) {
        // Make the circle bigger
        d3.select(this)
          .select("circle")
          .transition()
          .attr("r", 7)
          .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
          })
          .style("stroke-width", "3px");

        d3.select(this)
          .select("text")
          .attr("x", function(d) {
            return d.children || d._children ? d.name.length*2.5 : 10;
          })
          .text(function(d){ return d.name})
          .style("font-weight", "bold")
          .style("fill", "blue")
          .style("font-size", "12px");
      }

      function mouseout(d) {
        // set back circle\'s original radius
        d3.select(this)
          .select("circle")
          .transition()
          .attr("r", 4.5)
          .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
          })
          .style("stroke-width", "1.5px");

        d3.select(this)
          .select("text")
          .attr("x", function(d) {
            return d.children || d._children ? d.sname.length*2.5 : 10;
          })
          .text(function(d){ return d.sname})
          .style("font-weight", "normal")
          .style("fill", "black")
          .style("font-size", "10px");
      }

      // Helper functions for collapsing and expanding nodes.

      function collapse(d) {
          if (d.children) {
              d._children = d.children;
              d._children.forEach(collapse);
              d.children = null;
          }
      }
  
      function expand(d) {
          if (d._children) {
              d.children = d._children;
              d.children.forEach(expand);
              d._children = null;
          }
      }

      function update(source) {
        // Compute the new height, function counts total children of root node and sets tree height accordingly.
        // This prevents the layout looking squashed when new nodes are made visible or looking sparse when nodes are removed
        // This makes the layout more consistent.
        var levelWidth = [1];
        var childCount = function(level, n) {
        
          if (n.children && n.children.length > 0) {
            if (levelWidth.length <= level + 1) levelWidth.push(0);
            
            levelWidth[level + 1] += n.children.length;
            n.children.forEach(function(d) {
              childCount(level + 1, d);
            });
          }
        };

        childCount(0, root);
        var newHeight = d3.max(levelWidth) * 50; // 50 pixels per line  
        //tree = tree.size([newHeight, width]);
        
        // Compute the new tree layout.
        var nodes = tree.nodes(root).reverse(),
        links = tree.links(nodes);
        
        // Set widths between levels based on maxLabelLength.
        nodes.forEach(function(d) {
          //d.y = (d.depth * (maxLabelLength * 10)); //maxLabelLength * 10px
          // alternatively to keep a fixed scale one can set a fixed depth per level
          // Normalize for fixed-depth by commenting out below line
          d.y = (d.depth * 180); //180px per level.
        });
        
        // Update the node...
        node = svgGroup.selectAll("g.node")
          .data(nodes, function(d) {
            return d.id || (d.id = ++i);
          });
        
        // Enter any new nodes at the parent\'s previous position.
        var nodeEnter = node.enter().append("g")
          .attr("class", "node")
          .attr("transform", function(d) {
            return "translate(" + source.y0 + "," + source.x0 + ")";
          })
          .on("click", click)
          .on("mouseover", mouseover)
          .on("mouseout", mouseout);
        
        nodeEnter.append("circle")
          .attr("class", "nodeCircle")
          .attr("r", 0)
          .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
          });
        
        nodeEnter.append("text")
          .attr("x", function(d) {
            return d.children || d._children ? -10 : 10;
          })
          .attr("dy", function(d) {
            return d.children || d._children ? "1.5em" : ".35em";
          })
          .attr("class", "nodeText")
          .attr("text-anchor", function(d) {
            return d.children || d._children ? "end" : "start";
          })
          .text(function(d) {
            return d.sname;
          })
          .style("fill-opacity", 0);
        
        // Update the text to reflect whether node has children or not.
        node.select("text")
          .attr("x", function(d) {
            return d.children || d._children ? d.sname.length*2.5 : 10;
          })
          .attr("text-anchor", function(d) {
            return d.children || d._children ? "end" : "start";
          })
          .text(function(d) {
            return d.sname;
          });
        
        // Change the circle fill depending on whether it has children and is collapsed
        node.select("circle.nodeCircle")
          .attr("r", 4.5)
          .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
          });
        
        // Transition nodes to their new position.
        var nodeUpdate = node.transition()
          .duration(duration)
          .attr("transform", function(d) {
            return "translate(" + d.y + "," + d.x + ")";
          });
        
        // Fade the text in
        nodeUpdate.select("text")
          .style("fill-opacity", 1);
        
        // Transition exiting nodes to the parent\'s new position.
        var nodeExit = node.exit().transition()
          .duration(duration)
          .attr("transform", function(d) {
          return "translate(" + source.y + "," + source.x + ")";
          })
          .remove();
        
        nodeExit.select("circle")
          .attr("r", 0);
        
        nodeExit.select("text")
          .style("fill-opacity", 0);
        
        // Update the link...
        var link = svgGroup.selectAll("path.link")
          .data(links, function(d) {
            return d.target.id;
          });
        
        // Enter any new links at the parent\'s previous position.
        link.enter().insert("path", "g")
          .attr("class", "link")
          .attr("d", function(d) {
            var o = {
              x: source.x0,
              y: source.y0
            };
            return diagonal({
              source: o,
              target: o
            });
          });
        
        // Transition links to their new position.
        link.transition()
          .duration(duration)
          .attr("d", diagonal);
        
        // Transition exiting nodes to the parent\'s new position.
        link.exit().transition()
                .duration(duration)
                .attr("d", function(d) {
                    var o = {
                        x: source.x,
                        y: source.y
                    };
                    return diagonal({
                        source: o,
                        target: o
                    });
                })
                .remove();
    
        // Stash the old positions for transition.
        nodes.forEach(function(d) {
          d.x0 = d.x;
          d.y0 = d.y;
        });
      }
    
      
    
    };
    
    $(document).ready(function(){
      draw{{chartId}}()
    });
    
    </script>'
  },
  getPayload = function(chartId){
    #treeD = toChain(params[!(names(params) %in% c('dom', 'data'))], "d3.treeDiagram()")
    chartParams = RJSONIO:::toJSON(params)
    list(chartParams = chartParams, data=toJSONArray(params[['data']]),
         chartId = chartId, lib = basename(lib), liburl = LIB$url
    )
  }
))
