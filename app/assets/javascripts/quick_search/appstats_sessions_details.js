
(function() {
    var Globals = {};
    Globals["#graph_sessions_location"] = {};
    Globals["#graph_sessions_device"] = {};

    $(document).on("turbo:load", function() {
        if ($("#graph_sessions_location").length) {
            d3.select("#locationIconContainer").append("i")
                .attr("class", "fa fa-spinner fa-spin fa-5x fa-fw big-icon")
                .attr("id", "locationIcon");
            d3.select("#deviceIconContainer").append("i")
                .attr("class", "fa fa-spinner fa-spin fa-5x fa-fw big-icon")
                .attr("id", "deviceIcon");
            // Redraw graph if the date range is changed
            document.getElementById("dateButton").addEventListener("click", function() {
                var from = $("#from").datepicker("getDate");
                var to = new Date($("#to").datepicker("getDate").getTime() + 1000*60*60*24);
                document.getElementById("numDays").innerHTML = "" + parseInt((to-from)/(1000*60*60*24));
                var usePercLoc = Globals["#graph_sessions_location"].UsePerc
                $.ajax({
                    type: "GET",
                    contentType: "application/json; charset=utf-8",
                    url: window.QuickSearchRoutes.data_sessions_location,
                    dataType: "json",
                    data: {
                        "start_date": from,
                        "end_date": to,
                        "use_perc": usePercLoc
                    },
                    success: function(sessionsDataSet) {
                        var dataMain = _.cloneDeep(sessionsDataSet);
                        draw_graph_sessions_details("#graph_sessions_location", dataMain, false, true, usePercLoc);
                    },
                    error: function(result) {
                        error();
                    }
                });
                var usePercDev = Globals["#graph_sessions_device"].UsePerc;
                $.ajax({
                    type: "GET",
                    contentType: "application/json; charset=utf-8",
                    url: window.QuickSearchRoutes.data_sessions_device,
                    dataType: "json",
                    data: {
                        "start_date": from,
                        "end_date": to,
                        "use_perc": usePercDev
                    },
                    success: function(sessionsDataSet) {
                        var dataMain = _.cloneDeep(sessionsDataSet);
                        draw_graph_sessions_details("#graph_sessions_device", dataMain, false, true, usePercDev);
                    },
                    error: function(result) {
                        error();
                    }
                });
            });
            $.ajax({
                type: "GET",
                contentType: "application/json; charset=utf-8",
                url: window.QuickSearchRoutes.data_sessions_location,
                dataType: "json",
                success: function(sessionsDataSet) {
                    d3.select("#locationIcon").transition().duration(250)
                        .style("opacity", .000001)
                        .remove();
                    var dataMain = _.cloneDeep(sessionsDataSet);
                    draw_graph_sessions_details("#graph_sessions_location", dataMain, false, false, false);

                    if ($("#graph_sessions_location").length) {
                        document.getElementsByClassName("session_location_filter")[0].addEventListener("click", process_filters);
                        document.getElementsByClassName("session_location_filter")[1].addEventListener("click", process_filters);
                    }
                },
                error: function(result) {
                    error();
                }
            });
            $.ajax({
                type: "GET",
                contentType: "application/json; charset=utf-8",
                url: window.QuickSearchRoutes.data_sessions_device,
                dataType: "json",
                success: function(sessionsDataSet) {
                    d3.select("#deviceIcon").transition().duration(250)
                        .style("opacity", .000001)
                        .remove();
                    var dataMain = _.cloneDeep(sessionsDataSet);
                    draw_graph_sessions_details("#graph_sessions_device", dataMain, false, false, false);

                    if ($("#graph_sessions_location").length) {
                        document.getElementsByClassName("session_device_filter")[0].addEventListener("click", process_filters);
                        document.getElementsByClassName("session_device_filter")[1].addEventListener("click", process_filters);
                    }
                },
                error: function(result) {
                    error();
                }
            });
        }
    });

    function error() {
        console.log("Error retrieving data");
    }

    function draw_graph_sessions_details(id, dataShared, transitioning, dateUpdated, usePerc) {
        if ($("#graph_sessions_location").length) {
            // General Variables
            var svg;            // SVG to contain graph
            var dataInt;        // Internal reference to graph dataset
            // Dimension Variables
            var margin;         // Blank space around top graph (focus)
            var margin2;        // Blank space around bottom graph (context)
            var width;          // Drawable width of focus/context (not including margins)
            var height;         // Drawable height of focus (not including margins)
            var height2;        // Drawable height of context (not including margins)
            // Date Variables
            var parseDate;      // Function to parse dates into proper format
            // Scale Variables
            var x;              // X-scale for focus graph 
            var x2;             // X-scale for context graph
            var y;              // Y-scale for focus graph
            var y2;             // Y-scale for context graph
            // Brush and Zoom Variables
            var brush;          // Object that allows domain selection by brush movement
            var zoom;           // Object that allows domain selection by zooming
            // Axis Variables
            var xAxis;          // X-axis for focus graph
            var xAxis2;         // X-axis for context graph
            var yAxis;          // Y-axis for focus graph
            var yAxisFormat;    // Conditional format for yAxis, depending on if displaying percentages or raw values
            // Area Variables
            var area;           // Bottom area for focus graph
            var areaTop;        // Top area for focus graph
            var area2;          // Bottom area for context graph
            var area2Top;       // Top area for context graph
            // Additional Data Variables
            var legendData;     // Data for legend construction (class and text fields)
            // Selection Variables
            var gAllSelection;          // Selection for overarching group
            var gAll;                   // Group containing all elements
            var focusSelection;         // Selection for focus group
            var focus;                  // Group containing all focus elements
            var contextSelection;       // Selection for context group
            var context;                // Group containing all context elements
            var clipSelection;          // Selection for clip path
            var legendGroupSelection;   // Selection for legend group
            var legendGroup;            // Group containing all legnend information
            var legendRectSelection;    // Selection for legend rectangles
            var legendTextSelection;    // Selection for legend text
            var xAxisSelection;         // Selection for xAxis
            var yAxisSelection;         // Selection for yAxis
            var titleSelection;         // Selection for title
            var focusPathSelection;     // Selection for bottom focus path (area)
            var focusPathTopSelection;  // Selection for top focus path (area)
            var xAxis2Selection;        // Selection for xAxis2
            var contextPathSelection;   // Selection for bottom context path (area)
            var contextPathTopSelection;// Selection for top context path (area)
            var brushSelection;         // Selection for brush
            var zoomSelection;          // Selection for zoom
            // Update global percent flag
            Globals[id].UsePerc = usePerc;

            // Initialize General Variables ///////////////////////////////////////////////////////////
            svg = d3.select(id);

            dataInt = dataShared;

            // Initialize Dimension Variables /////////////////////////////////////////////////////////
            margin = {
                top: 50,
                right: 20,
                bottom: 110,
                left: 40
            };
            margin2 = {
                top: 430,
                right: 20,
                bottom: 30,
                left: 40
            };
            width = +svg.attr("width") - margin.left - margin.right;
            height = +svg.attr("height") - margin.top - margin.bottom;
            height2 = +svg.attr("height") - margin2.top - margin2.bottom;
            
            // Initialize Date Variables and Parse Dates //////////////////////////////////////////////
            parseDate = d3.timeParse("%Y-%m-%d");

            dataInt.forEach(function(d) {
                d.date = parseDate(d.date);
            });

            // Initialize Scale Variables /////////////////////////////////////////////////////////////
            x = d3.scaleTime().range([0, width]);
            x2 = d3.scaleTime().range([0, width]);
            y = d3.scaleLinear().range([height, 0]);
            y2 = d3.scaleLinear().range([height2, 0]);

            // Set domains
            x2.domain(d3.extent(dataInt, function(d) {
                return d.date;
            }));
            if (_.isEqual(undefined, Globals[id].Domain)) {
                x.domain(d3.extent(dataInt, function(d) {
                    return d.date;
                }));
            } else {
                var lb, ub;
                if (Globals[id].Domain[0] < x2.domain()[0]) {
                    lb = x2.domain()[0];
                } else {
                    lb = Globals[id].Domain[0];
                }
                if (Globals[id].Domain[1] > x2.domain()[1]) {
                    ub = x2.domain()[1];
                } else {
                    ub = Globals[id].Domain[1];
                }
                if(Globals[id].Domain[0]>x2.domain()[1] || Globals[id].Domain[1]<x2.domain()[0]) {
                    lb = x2.domain()[0];
                    ub = x2.domain()[1];
                }
                x.domain([lb, ub]);
            }
            y.domain([0, d3.max(dataInt, function(d) {
                return d.on + d.off;
            })]);
            y2.domain(y.domain());
            

            // Initialize Brush and Zoom Variables ////////////////////////////////////////////////////
            brush = d3.brushX()
                .extent([
                    [0, 0],
                    [width, height2]
                ])
                .on("brush end", brushed);

            zoom = d3.zoom()
                .scaleExtent([1, 1000])
                .translateExtent([
                    [0, 0],
                    [width, height]
                ])
                .extent([
                    [0, 0],
                    [width, height]
                ])
                .on("zoom", zoomed);

            // Initialize Axis Variables //////////////////////////////////////////////////////////////
            xAxis = d3.axisBottom(x);
            xAxis2 = d3.axisBottom(x2);
            yAxis = d3.axisLeft(y);
            yAxisFormat = usePerc ? d3.format(".0%") : null;

            yAxis.tickFormat(yAxisFormat);

            // Initialize Area Variables //////////////////////////////////////////////////////////////
            area = d3.area()
                .curve(d3.curveMonotoneX)
                .x(function(d) {
                    return x(d.date);
                })
                .y0(height)
                .y1(function(d) {
                    return y(d.on);
                });

            areaTop = d3.area()
                .curve(d3.curveMonotoneX)
                .x(function(d) {
                    return x(d.date);
                })
                .y0(function(d) {
                    return y(d.on)+5;
                })
                .y1(function(d) {
                    return y(d.on + d.off);
                });

            area2 = d3.area()
                .curve(d3.curveMonotoneX)
                .x(function(d) {
                    return x2(d.date);
                })
                .y0(height2)
                .y1(function(d) {
                    return y2(d.on);
                });

            area2Top = d3.area()
                .curve(d3.curveMonotoneX)
                .x(function(d) {
                    return x2(d.date);
                })
                .y0(function(d) {
                    return y2(d.on)+1;
                })
                .y1(function(d) {
                    return y2(d.on + d.off);
                });

            // Initialize Additional Data Variables ///////////////////////////////////////////////////
            legendData = [{areaClass: "legendRect",         locationText: "On Campus",  deviceText: "On Mobile Device"},
                          {areaClass: "lightLegendRect",    locationText: "Off Campus", deviceText: "On Non-Mobile Device"}];

            // Make overarching group /////////////////////////////////////////////////////////////////
            gAllSelection = svg.selectAll(".gAll").data([dataInt]);

            gAllSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            gAllSelection.enter().append("g")
                .attr("class", "gAll")
                .attr("transform", "translate(0,0)");

            gAll = svg.select(".gAll");

            // Make focus
            focusSelection = gAll.selectAll(".focus").data([dataInt]);

            focusSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            focusSelection.enter().append("g")
                .attr("class", "focus")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

            focus = gAll.select(".focus");

            // Make context
            contextSelection = gAll.selectAll(".context").data([dataInt]);

            contextSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            contextSelection.enter().append("g")
                .attr("class", "context")
                .attr("transform", "translate(" + margin2.left + "," + margin2.top + ")");

            context = gAll.select(".context");

            // Make clip path
            clipSelection = gAll.selectAll("defs").data([dataInt]);

            clipSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            clipSelection.enter().append("defs").append("clipPath")
                .attr("id", "clip")
                .append("rect")
                .attr("width", width)
                .attr("height", height);

            // Make legendGroup
            legendGroupSelection = gAll.selectAll(".legend").data([dataInt]);

            legendGroupSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            legendGroupSelection.enter().append("g")
                .attr("class", "legend")
                .attr("transform", "translate(" + margin.left + "," + 0 + ")");

            legendGroup = svg.select(".legend");

            // Make legendRects and legendText
            legendRectSelection = legendGroup.selectAll(".legendRect, .lightLegendRect").data(legendData);

            legendRectSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            legendRectSelection.enter().append("rect")
                .style("opacity", .000001)
                .attr("class", function(d, i) {
                    return d.areaClass;
                })
                .attr("width", width/32)
                .attr("height", width/32)
                .attr("transform", function (d,i) { 
                    return "translate(" + (width/5 + i*2*width/5) + "," + 5 + ")";
                })
                .transition().duration(500)
                .style("opacity", 1);

            var legendTextSelection = legendGroup.selectAll(".legendText").data(legendData);

            legendTextSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            legendTextSelection.enter().append("text")
                .style("opacity", .000001)
                .attr("class", "legendText")
                .text(function(d) {
                    if (id=="#graph_sessions_location") {
                        return d.locationText;
                    } else {
                        return d.deviceText;
                    }
                })
                .attr("transform", function(d, i) {
                    return "translate(" + (width/5 + i*2*width/5 + width/32 + 5) + "," + (5 + 3*width/128) + ")";
                })
                .transition().duration(500)
                .style("opacity", 1);

            // Make focus x axis
            xAxisSelection = focus.selectAll(".xAxis").data([dataInt]);

            xAxisSelection.transition().duration(750)
                .call(xAxis);
            xAxisSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            xAxisSelection.enter().append("g")
                .style("opacity", .000001)
                .attr("class", "xAxis")
                .attr("transform", "translate(0," + height + ")")
                .call(xAxis)
                .transition().duration(500)
                .style("opacity", 1);

            // Make focus y axis
            yAxisSelection = focus.selectAll(".yAxis").data([dataInt]);

            yAxisSelection.transition().duration(750)
                .call(yAxis);
            yAxisSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            yAxisSelection.enter().append("g")
                .style("opacity", .000001)
                .attr("class", "yAxis")
                .attr("transform", "translate(0,0)")
                .call(yAxis)
                .transition().duration(500)
                .style("opacity", 1);

            // Make focus path
            focusPathSelection = focus.selectAll(".area").data([dataInt]);

            focusPathSelection.datum(dataInt).transition().duration(750)
                .attr("d", area);
            focusPathSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            focusPathSelection.enter().append("path")
                .style("opacity", .000001)
                .datum(dataInt)
                .attr("class", "area")
                .transition().duration(500)
                .style("opacity", 1);

            focusPathTopSelection = focus.selectAll(".areaLight").data([dataInt]);

            focusPathTopSelection.datum(dataInt).transition().duration(750)
                .attr("d", areaTop);
            focusPathTopSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            focusPathTopSelection.enter().append("path")
                .style("opacity", .000001)
                .datum(dataInt)
                .attr("class", "areaLight")
                .transition().duration(500)
                .style("opacity", 1);

            // Make context x axis
            xAxis2Selection = context.selectAll(".xAxis").data([dataInt]);

            xAxis2Selection.transition().duration(500)
                .call(xAxis2);
            xAxis2Selection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            xAxis2Selection.enter().append("g")
                .style("opacity", .000001)
                .attr("class", "xAxis")
                .attr("transform", "translate(0," + height2 + ")")
                .call(xAxis2)
                .transition().duration(500)
                .style("opacity", 1);

            // Make context path
            contextPathSelection = context.selectAll(".area").data([dataInt]);

            contextPathSelection.datum(dataInt).transition().duration(750)
                .attr("d", area2);
            contextPathSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            contextPathSelection.enter().append("path")
                .style("opacity", .000001)
                .datum(dataInt)
                .attr("class", "area")
                .attr("d", area2)
                .transition().duration(500)
                .style("opacity", 1);

            contextPathTopSelection = context.selectAll(".areaLight").data([dataInt]);

            contextPathTopSelection.datum(dataInt).transition().duration(750)
                .attr("d", area2Top);
            contextPathTopSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            contextPathTopSelection.enter().append("path")
                .style("opacity", .000001)
                .datum(dataInt)
                .attr("class", "areaLight")
                .attr("d", area2Top)
                .transition().duration(500)
                .style("opacity", 1);

            // Make brush container
            brushSelection = context.selectAll(".brush").data([dataInt]);

            brushSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            brushSelection.enter().append("g")
                .attr("class", "brush")
                .call(brush)
                .call(brush.move, x.range())
                .merge(brushSelection)
                .style("opacity", 1)
                .call(brush);

            // Misc ///////////////////////////////////////////////////////////////////////////////////
            // Have to prevent zoom or brush temporarily for transitions to execute
            if (transitioning) {
                setTimeout(function() {
                    transitioning = false;
                }, 50);
            } // If not on transition, fade in brush
            else {
                svg.selectAll(".brush")
                    .style("opacity", .000001)
                    .transition().duration(500)
                    .style("opacity", 1);
            }

            // Before updating domains, move brush to domain it was previously set to
            if (dateUpdated) {
                var lb, ub;
                if (x2(Globals[id].Domain[0]) < 0) {
                    lb = 0;
                } else {
                    lb = x2(Globals[id].Domain[0]);
                }
                if (x2(Globals[id].Domain[1]) > width) {
                    ub = width;
                } else {
                    ub = x2(Globals[id].Domain[1]);
                }
                if(Globals[id].Domain[0]>x2.domain()[1] || Globals[id].Domain[1]<x2.domain()[0]) {
                    lb = 0;
                    ub = width;
                }
                context.select(".brush").call(brush.move, [lb, ub]);
                context.select(".brush").transition().duration(500)
                    .style("opacity", 1);
            }

            // Make zoom container
            zoomSelection = gAll.selectAll(".zoom").data([dataInt]);

            zoomSelection.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            zoomSelection.enter().append("rect")
                .attr("class", "zoom")
                .attr("width", width)
                .attr("height", height)
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
                .merge(zoomSelection)
                .call(zoom);


            function brushed(event) {
                if (!transitioning) {
                    if (event.sourceEvent && event.sourceEvent.type === "zoom") return;
                    var s = event.selection || x2.range();
                    x.domain(s.map(x2.invert, x2));
                    Globals[id].Domain = x.domain();
                    focus.select(".area").attr("d", area);
                    focus.select(".areaLight").attr("d", areaTop);
                    focus.select(".xAxis").call(xAxis);
                    svg.select(".zoom").call(zoom.transform, d3.zoomIdentity
                        .scale(width / (s[1] - s[0]))
                        .translate(-s[0], 0));
                }
            }

            function zoomed(event) {
                if (!transitioning) {
                    if (event.sourceEvent && event.sourceEvent.type === "brush") return;
                    var t = event.transform;
                    x.domain(t.rescaleX(x2).domain());
                    Globals[id].Domain = x.domain();
                    focus.select(".area").attr("d", area);
                    focus.select(".areaLight").attr("d", areaTop);
                    focus.select(".xAxis").call(xAxis);
                    context.select(".brush").call(brush.move, x.range().map(t.invertX, t));
                }
            }
        }
    }

    function process_filters() {
        var loc = document.querySelector('input[name = "loc"]:checked').value;
        var dev = document.querySelector('input[name = "dev"]:checked').value;
        var from = $("#from").datepicker("getDate");
        var to = new Date($("#to").datepicker("getDate").getTime() + 1000*60*60*24);

        var usePercLoc = _.isEqual(loc,"perc") ? true : false;
        $.ajax({
            type: "GET",
            contentType: "application/json; charset=utf-8",
            url: window.QuickSearchRoutes.data_sessions_location,
            dataType: "json",
            data: {
                "start_date": from,
                "end_date": to,
                "use_perc": usePercLoc
            },
            success: function(sessionsDataSet) {
                var dataMain = _.cloneDeep(sessionsDataSet);
                draw_graph_sessions_details("#graph_sessions_location", dataMain, true, false, usePercLoc);
            },
            error: function(result) {
                error();
            }
        });

        var usePercDev = _.isEqual(dev,"perc") ? true : false;
        $.ajax({
            type: "GET",
            contentType: "application/json; charset=utf-8",
            url: window.QuickSearchRoutes.data_sessions_device,
            dataType: "json",
            data: {
                "start_date": from,
                "end_date": to,
                "use_perc": usePercDev
            },
            success: function(sessionsDataSet) {
                var dataMain = _.cloneDeep(sessionsDataSet);
                draw_graph_sessions_details("#graph_sessions_device", dataMain, true, false, usePercDev);
            },
            error: function(result) {
                error();
            }
        });
    }
})();