
(function() {
    var Globals = {};

    $(document).on("turbo:load", function() {
        if ($("#graph_top_searches").length) {
            d3.select("#tsIconContainer").append("i")
                .attr("class", "fa fa-spinner fa-spin fa-5x fa-fw big-icon")
                .attr("id", "tsIcon");
            // Redraw graph if the date range is changed
            document.getElementById("dateButton").addEventListener("click", function() { 
                var from = $("#from").datepicker("getDate");
                var to = new Date($("#to").datepicker("getDate").getTime() + 1000*60*60*24);
                document.getElementById("numDays").innerHTML = "" + parseInt((to-from)/(1000*60*60*24));
                $.ajax({
                    type: "GET",
                    contentType: "application/json; charset=utf-8",
                    url: window.QuickSearchRoutes.data_top_searches,
                    dataType: "json",
                    data: {
                        "start_date": from,
                        "end_date": to,
                        "num_results": document.getElementById("num").value
                    },
                    success: function(searchDataSet) {
                        var searchData = _.cloneDeep(searchDataSet);
                        Globals.OriginalData = searchData;
                        Globals.Data = searchData;
                        sort_search_data(Globals.Sort);
                    },
                    error: function(result) {
                        error();
                    }
                });
            });
            $.ajax({
                type: "GET",
                contentType: "application/json; charset=utf-8",
                url: window.QuickSearchRoutes.data_top_searches,
                dataType: "json",
                success: function(searchDataSet) {
                    d3.select("#tsIcon").transition().duration(250)
                        .style("opacity", .000001)
                        .remove();
                    var searchData = _.cloneDeep(searchDataSet);
                    Globals.OriginalData = searchData;
                    Globals.Data = searchData;
                    Globals.Sort = 0;
                    Globals.Height = 450;
                    draw_graph_top_searches();
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

    function draw_graph_top_searches() {
        if ($("#graph_top_searches").length) {
            // General Variables
            var svg;            // SVG to contain graph
            var dataInt;        // Internal reference to graph dataset
            var sortStates;     // Array indicating the currently selected sort state
            var key;            // Key function to maintain object constancy
            var triangle;       // Triangle object for sort buttons
            // Dimension Variables
            var margin;         // Blank space around edge of SVG left as margin
            var rowHeight;      // Height of each row of data
            var width;          // Drawable width of SVG (not including margins)
            var height;         // Drawable height of SVG (not including margins)
            var oldHeight;      // Previous height of SVG
            var textPadding;    // Padding around text elements
            var barHeight;      // Height of data bars
            var rankWidth;      // Width of rank column
            var categoryWidth;  // Width of category column
            var countWidth;     // Width of count column
            var percentWidth;   // Width of percent column
            var cumPercentWidth;// Width of cumulative percent column
            var percBarCenter;  // Center x for count/percent data bar
            var cumPercBarStart;// Beginning x for cumulative percent data bar
            var triangleSpacing;// Space around triangular sort buttons
            // Scale Variables
            var percScale;      // Scale for count/percent data bar
            var cumPercScale;   // Scale for cumulative percent data bar
            // Selection Variables
            var groupEnter;     // Entry selection for gAll
            var gAll;           // Group containing all elements
            var headGroupEnter; // Entry selection for headRow
            var headRow;        // Group containing all head elements
            var headEnter;      // Entry selection for all head elements
            var triangles;      // Sort triangles
            var dataGroupEnter; // Entry selection for dataRows
            var dataRows;       // Group containing all data elements
            var dataRects;      // Background rectangles
            var dataRanks;      // Rank text
            var dataLabels;     // Label text
            var dataClicks;     // Click text
            var dataPercents;   // Percent text
            var dataCumPercents;// Cumulative percent text
            var percBar;        // Count/percent data bar
            var cumPercBar;     // Cumulative percent data bar
            var lightBorder;    // Light border (surrounds all elements)
            var darkBorder;     // Dark border (surrounds data elements)

            // Initialize General Variables ///////////////////////////////////////////////////////////
            svg = d3.select("#graph_top_searches");

            dataInt = Globals.Data;

            sortStates = [0, 0, 0, 0];
            sortStates[Globals.Sort] = 1;

            key = function(d) {
                return d.key;
            };

            triangle = d3.symbol().type(d3.symbolTriangle).size(20);

            // Initialize Dimension Variables /////////////////////////////////////////////////////////
            margin = {
                top: 20,
                right: 20,
                bottom: 20,
                left: 20
            };
            rowHeight = 35;
            width = +svg.attr("width") - margin.left - margin.right;
            height = (dataInt.length + 1) * rowHeight;
            oldHeight = Globals.Height;
            textPadding = 5;
            barHeight = 25;
            rankWidth = 2 * width / 16;
            categoryWidth = 4 * width / 16;
            countWidth = 2 * width / 16;
            percentWidth = 3 * width / 16;
            cumPercentWidth = 5 * width / 16;
            percBarCenter = rankWidth + categoryWidth + countWidth + 13 * d3.max(dataInt, function(d) {
                return d.count.toString().length;
            });
            cumPercBarStart = rankWidth + categoryWidth + countWidth + percentWidth + 3 * textPadding + 13 * d3.max(dataInt, function(d) {
                return d.cum_percentage.toString().length;
            });
            triangleSpacing = 15;

            // Initialize Scale Variables /////////////////////////////////////////////////////////////
            percScale = d3.scaleLinear().rangeRound([0, countWidth + percentWidth - 100]);
            percScale.domain([0, d3.max(dataInt, function(d) {
                return d.cum_percentage
            })]);

            cumPercScale = d3.scaleLinear().rangeRound([0, countWidth + percentWidth - 100]);
            cumPercScale.domain([0, d3.max(dataInt, function(d) {
                return d.cum_percentage
            })]);

            // Misc ///////////////////////////////////////////////////////////////////////////////////
            // Transition the svg height depending on previous height
            svg.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("height", height + margin.top + margin.bottom)
                .on("end", function(d) {
                    Globals.Height = height;
                });

            // Make overarching group /////////////////////////////////////////////////////////////////
            groupEnter = svg.selectAll("g").data([dataInt]).enter();

            groupEnter.append("g")
                .attr("class", "gAll");

            gAll = svg.select(".gAll")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

            // Make header row ////////////////////////////////////////////////////////////////////////
            headGroupEnter = gAll.selectAll(".headRow").data([dataInt]).enter();

            headGroupEnter.append("g")
                .attr("class", "headRow");

            headRow = gAll.select(".headRow")
                .attr("transform", "translate(0,0)");

            headEnter = headRow.selectAll("rect").data([dataInt]).enter();

            // Make background rect
            headEnter.append("rect")
                .attr("class", "darkBar")
                .attr("x", 0)
                .attr("y", 0)
                .attr("width", width)
                .attr("height", rowHeight);

            // Make rank text & sort rect
            headEnter.append("text")
                .text("Rank")
                .attr("class", "headText")
                .attr("transform", "translate(" + textPadding + "," + (rowHeight / 2 + textPadding) + ")");

            headEnter.append("rect")
                .attr("class", "sortRect")
                .attr("x", (rankWidth - 2 * triangleSpacing))
                .attr("y", 0)
                .attr("width", 2 * triangleSpacing)
                .attr("height", rowHeight)
                .on("click", function(d) {
                    if (Globals.Sort == 0) {
                        sort_search_data(1);
                    } else {
                        sort_search_data(0);
                    }
                });

            // Make category text & sort rect
            headEnter.append("text")
                .text("Query")
                .attr("class", "headText")
                .attr("transform", "translate(" + (rankWidth + textPadding) + "," + (rowHeight / 2 + textPadding) + ")");

            headEnter.append("rect")
                .attr("class", "sortRect")
                .attr("x", (rankWidth + categoryWidth - 2 * triangleSpacing))
                .attr("y", 0)
                .attr("width", 2 * triangleSpacing)
                .attr("height", rowHeight)
                .on("click", function(d) {
                    if (Globals.Sort == 2) {
                        sort_search_data(3);
                    } else {
                        sort_search_data(2);
                    }
                });

            // Make count, percent, & cumulative percent text
            headEnter.append("text")
                .text("Count")
                .attr("class", "headText")
                .attr("transform", "translate(" + (rankWidth + categoryWidth + textPadding) + "," + (rowHeight / 2 + textPadding) + ")");

            headEnter.append("text")
                .text("Percent")
                .attr("class", "percentText")
                .attr("transform", "translate(" + (rankWidth + categoryWidth + countWidth + percentWidth - textPadding) + "," + (rowHeight / 2 + textPadding) + ")");

            headEnter.append("text")
                .text("Cumulative Percent")
                .attr("class", "headText")
                .attr("transform", "translate(" + (rankWidth + categoryWidth + countWidth + percentWidth + 3 * textPadding) + "," + (rowHeight / 2 + textPadding) + ")");

            // Make sort triangles
            triangles = headRow.selectAll("path").data(sortStates);

            triangles.enter().append("path")
                .attr("d", triangle)
                .attr("pointer-events", "none")
                .attr("transform", function(d, i) {
                    if (i == 0) {
                        return "translate(" + (rankWidth - triangleSpacing) + "," + (rowHeight / 2 - textPadding) + ")";
                    } else if (i == 1) {
                        return "translate(" + (rankWidth - triangleSpacing) + "," + (rowHeight / 2 + textPadding) + ") rotate(180)";
                    } else if (i == 2) {
                        return "translate(" + (rankWidth + categoryWidth - triangleSpacing) + "," + (rowHeight / 2 - textPadding) + ")";
                    } else if (i == 3) {
                        return "translate(" + (rankWidth + categoryWidth - triangleSpacing) + "," + (rowHeight / 2 + textPadding) + ") rotate(180)";
                    }
                })
                .merge(triangles)
                .transition().duration(500)
                .attr("fill", function(d, i) {
                    if (d) {
                        return "steelblue";
                    } else {
                        return "lightsteelblue";
                    }
                });

            // Make data rows /////////////////////////////////////////////////////////////////////////
            dataGroupEnter = gAll.selectAll(".dataRows").data([dataInt]).enter();

            dataGroupEnter.append("g")
                .attr("class", "dataRows");

            dataRows = gAll.select(".dataRows")
                .attr("transform", "translate(0,0)");

            // Make background rects
            dataRects = dataRows.selectAll(".darkBar, .lightBar").data(dataInt, key);

            dataRects.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("y", function(d, i) {
                    return (i + 1) * rowHeight;
                });
            dataRects.exit().remove();
            dataRects.enter().append("rect")
                .style("opacity", .000001)
                .attr("class", function(d, i) { return "darkBar"; })
                .attr("x", 0)
                .attr("y", function(d, i) {
                    return (i + 1) * rowHeight;
                })
                .attr("width", width)
                .attr("height", rowHeight)
                .transition().delay(750).duration(500)
                .style("opacity", 1);

            // Make rank text
            dataRanks = dataRows.selectAll(".dataRank").data(dataInt, key);

            dataRanks.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("transform", function(d, i) {
                    return "translate(" + textPadding + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .text(function(d) {
                    return d.rank;
                });
            dataRanks.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            dataRanks.enter().append("text")
                .style("opacity", .000001)
                .text(function(d) {
                    return d.rank;
                })
                .attr("class", "dataRank")
                .attr("transform", function(d, i) {
                    return "translate(" + textPadding + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .transition().delay(750).duration(500)
                .style("opacity", 1);

            // Make label text
            dataLabels = dataRows.selectAll(".dataLabel").data(dataInt, key);

            dataLabels.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .text(function(d) {
                    if (d.label.length > 25) {
                        return d.label.slice(0, 20) + "...";
                    } else {
                        return d.label;
                    }
                });
            dataLabels.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            dataLabels.enter().append("text")
                .style("opacity", .000001)
                .text(function(d) {
                    if (d.label.length > 25) {
                        return d.label.slice(0, 20) + "...";
                    } else {
                        return d.label;
                    }
                })
                .attr("class", "dataLabel")
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .transition().delay(750).duration(500)
                .style("opacity", 1);

            // Make click text
            var dataClicks = dataRows.selectAll(".dataClick").data(dataInt, key);

            dataClicks.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + categoryWidth + textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .text(function(d) {
                    return d.count;
                });
            dataClicks.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            dataClicks.enter().append("text")
                .style("opacity", .000001)
                .text(function(d) {
                    return d.count;
                })
                .attr("class", "dataClick")
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + categoryWidth + textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .transition().delay(750).duration(500)
                .style("opacity", 1);

            // Make percent text
            dataPercents = dataRows.selectAll(".dataPercent").data(dataInt, key);

            dataPercents.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + categoryWidth + countWidth + percentWidth - textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .text(function(d) {
                    return d.percentage + "%";
                });
            dataPercents.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            dataPercents.enter().append("text")
                .style("opacity", .000001)
                .text(function(d) {
                    return d.percentage + "%";
                })
                .attr("class", "dataPercent")
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + categoryWidth + countWidth + percentWidth - textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .transition().delay(750).duration(500)
                .style("opacity", 1);

            // Make click text
            dataCumPercents = dataRows.selectAll(".dataCumPercent").data(dataInt, key);

            dataCumPercents.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + categoryWidth + countWidth + percentWidth + 3 * textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .text(function(d) {
                    return d.cum_percentage + "%";
                });
            dataCumPercents.exit().transition().duration(500)
                .style("opacity", .000001)
                .remove();
            dataCumPercents.enter().append("text")
                .style("opacity", .000001)
                .text(function(d) {
                    return d.cum_percentage + "%";
                })
                .attr("class", "dataCumPercent")
                .attr("transform", function(d, i) {
                    return "translate(" + (rankWidth + categoryWidth + countWidth + percentWidth + 3 * textPadding) + "," + Math.floor((i + 1) * rowHeight + rowHeight / 2 + textPadding) + ")";
                })
                .transition().delay(750).duration(500)
                .style("opacity", 1);

            // Make perc bars
            percBar = dataRows.selectAll(".percBar").data(dataInt, key);

            percBar.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("y", function(d, i) {
                    return (i + 1) * rowHeight + (rowHeight - barHeight) / 2;
                })
                .attr("width", function(d) {
                    return percScale(d.percentage);
                })
                .attr("x", function(d) {
                    return percBarCenter - percScale(d.percentage) / 2;
                });
            percBar.exit().transition().duration(500)
                .attr("x", percBarCenter)
                .attr("width", 0)
                .remove();
            percBar.enter().append("rect")
                .attr("class", "percBar")
                .attr("x", function(d) {
                    return percBarCenter;
                })
                .attr("y", function(d, i) {
                    return (i + 1) * rowHeight + (rowHeight - barHeight) / 2;
                })
                .attr("width", function(d) {
                    return 0;
                })
                .attr("height", barHeight)
                .transition().delay(750).duration(500)
                .attr("x", function(d) {
                    return percBarCenter - percScale(d.percentage) / 2;
                })
                .attr("width", function(d) {
                    return percScale(d.percentage);
                });

            // Make cumulative perc bars
            cumPercBar = dataRows.selectAll(".cumPercBar").data(dataInt, key);

            cumPercBar.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("y", function(d, i) {
                    return (i + 1) * rowHeight + (rowHeight - barHeight) / 2;
                })
                .attr("width", function(d) {
                    return cumPercScale(d.cum_percentage);
                })
                .attr("x", function(d) {
                    return cumPercBarStart;
                });
            cumPercBar.exit().transition().duration(500)
                .attr("width", 0)
                .remove();
            cumPercBar.enter().append("rect")
                .attr("class", "cumPercBar")
                .attr("x", function(d) {
                    return cumPercBarStart;
                })
                .attr("y", function(d, i) {
                    return (i + 1) * rowHeight + (rowHeight - barHeight) / 2;
                })
                .attr("width", function(d) {
                    return 0;
                })
                .attr("height", barHeight)
                .transition().delay(750).duration(500)
                .attr("width", function(d) {
                    return cumPercScale(d.cum_percentage);
                });

            // Add borders ////////////////////////////////////////////////////////////////////////////
            lightBorder = gAll.selectAll(".lightBorder").data([dataInt]);

            lightBorder.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("height", height);
            lightBorder.exit().remove();
            lightBorder.enter().append("rect")
                .attr("class", "lightBorder")
                .attr("x", 0)
                .attr("y", 0)
                .attr("width", width)
                .attr("height", height);;

            darkBorder = gAll.selectAll(".darkBorder").data([dataInt]);

            darkBorder.transition().delay(function(d) {
                    if (oldHeight > height) {
                        return 500;
                    } else {
                        return 0;
                    }
                })
                .duration(750)
                .attr("height", height - rowHeight);
            darkBorder.exit().remove();
            darkBorder.enter().append("rect")
                .attr("class", "darkBorder")
                .attr("x", 0)
                .attr("y", rowHeight)
                .attr("width", width)
                .attr("height", height - rowHeight);
        }
    }

    function sort_search_data(sort) {
        Globals.Data = Globals.OriginalData.sort(function(a, b) {
            switch(sort) {
                case 0: return d3.ascending(a.rank,b.rank);
                case 1: return d3.ascending(b.rank,a.rank);

                case 2: return d3.ascending(a.label,b.label);
                case 3: return d3.ascending(b.label,a.label);
            }
        });

        // Update global sort
        Globals.Sort = sort;
        draw_graph_top_searches();
    }

})();