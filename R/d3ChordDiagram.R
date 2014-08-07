#' This code is from http://mostlyconjecture.com/2014/05/03/chord-diagrams-with-rcharts/
#' and https://github.com/timelyportfolio/rCharts_chord
ChordDiagram = setRefClass('ChordDiagram', contains = 'rCharts', methods = list(
  initialize = function(){
    callSuper()
    LIB <<- get_lib("d3_chord_diagram")
    lib <<- "chord_diagram"
    templates$script <<- '
    <script type="text/javascript">
    function draw{{chartId}}(){
    var params = {{{ chartParams }}}
    var chart = {{{ chordD }}}
    
    d3.select("#" + params.id) 
    .datum({"data":{{{data}}}, "matrix":{{{matrix}}} })
    .call(chart)
    return chart;
    };
    
    $(document).ready(function(){
    draw{{chartId}}()
    });
    
    </script>'
  },
  getPayload = function(chartId){
    chordD = toChain(params[!(names(params) %in% c('dom', 'data', 'matrix'))], "d3.chordDiagram()")
    chartParams = RJSONIO:::toJSON(params1)
    list(chordD = chordD, chartParams = chartParams, data=toJSONArray(params[['data']]),
         matrix=toJSONArray(params[['matrix']]), chartId = chartId, lib = basename(lib), liburl = LIB$url
    )
  }
))
