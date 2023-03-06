module QuickSearch
  class AppstatsController < ApplicationController
    include Auth

    before_action :get_dates, :days_in_sample #, :auth

    def data_general_statistics
      @graph_result = []

      clicks = Event.where(@range).where(:action => 'click').group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      @graph_result << process_time_query(clicks)

      sessions = Session.where(@range).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      @graph_result << process_time_query(sessions)

      searches = Search.where(@range).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      @graph_result << process_time_query(searches)
    end

    def data_general_table
      @table_result = []

      @table_result << { "clicks" => Event.where(@range).where(:action => 'click').count }
      @table_result << { "searches" => Search.where(@range).count }
      @table_result << { "sessions" => Session.where(@range).count }

    end

    def data_module_clicks
      clicks = Event.where(@range).where(excluded_categories).where(:action => 'click').group(:category).order("count_category DESC").count(:category)
      total_clicks = clicks.values.sum

      @clicks_module_result = process_module_result_query(clicks, "module", 0, 100, total_clicks)
    end

    def data_result_clicks
      clicks = Event.where(@range).where(:category => "result-types").where(:action => 'click').group(:item).order("count_item DESC").count(:item)
      total_clicks = clicks.values.sum

      @clicks_guides_result = process_module_result_query(clicks, "result", 0, 100, total_clicks)
    end

    def data_module_details
      category = params[:category]
      clicks = Event.where(:category => category).where(:action => 'click').where(@range).group(:item).order('count_category DESC').count(:category)
      total_clicks = clicks.values.sum

      @result = process_module_result_query(clicks, "module_details", category, 15, total_clicks)

      render_data
    end

    def data_top_searches
      num_results = params[:num_results] ? params[:num_results].to_i : 20
      searches = Search.where(:page => '/').where(@range).group(:query).order('count_query DESC').count(:query)
      total_searches = searches.sum {|k,v| v}

      @top_searches_result = process_searches_query(searches, num_results, total_searches)
    end

    def data_spelling_suggestions
      num_results = params[:num_results] ? params[:num_results].to_i : 20
      serves = Event.where(@range).where(:category => "spelling-suggestion", :action => 'serve').group(:item).order("count_category DESC").count(:category)
      clicks = Event.where(@range).where(:category => "spelling-suggestion", :action => 'click').group(:item).count(:category)

      @result = process_spelling_best_bets_query(serves, clicks, "spelling_suggestion", 0, num_results)
    end

    def data_spelling_details
      item = params[:item]
      serves = Event.where(@range).where(:category => "spelling-suggestion", :action => 'serve', :item => item).group(:query).order("count_query DESC").count(:query)
      clicks = Event.where(@range).where(:category => "spelling-suggestion", :action => 'click', :item => item).group(:query).count(:query)

      @result = process_spelling_best_bets_query(serves, clicks, "spelling_details", item, 15)

      render_data
    end

    def data_best_bets(best_bets_title)
      num_results = params[:num_results] ? params[:num_results].to_i : 20
      serves = Event.where(@range).where(:category => best_bets_title, :action => 'serve').group(:item).order("count_category DESC").count(:category)
      clicks = Event.where(@range).where(:category => best_bets_title, :action => 'click').group(:item).count(:category)
      puts serves
      puts clicks
      @result = process_spelling_best_bets_query(serves, clicks, "best_bet", 0, num_results)
    end

    def data_best_bets_details(best_bets_title)
      item = params[:item]
      serves = Event.where(@range).where(:category => best_bets_title, :action => 'serve', :item => item).group(:query).order("count_query DESC").count(:query)
      clicks = Event.where(@range).where(:category => best_bets_title, :action => 'click', :item => item).group(:query).count(:query)

      @result = process_spelling_best_bets_query(serves, clicks, "best_bet_details", item, 15)
    end

    # In order to obtain all filter cases, an integer corresponding to the following truth table is formed:
    # rowNumber   onCampus   offCampus    isMobile    notMobile | filters
    # 0           0          0            0           0         | Neither filter applied (default)
    # 1           0          0            0           1         | where(is_mobile=>false)
    # 2           0          0            1           0         | where(is_mobile=>true)
    # 3           0          0            1           1         | INVALID (isMobile & notMobile asserted)
    # 4           0          1            0           0         | where(on_campus=>false)
    # 5           0          1            0           1         | where(on_campus=>false, is_mobile=>false)
    # 6           0          1            1           0         | where(on_campus=>false, is_mobile=>true)
    # 7           0          1            1           1         | INVALID (isMobile & notMobile asserted)
    # 8           1          0            0           0         | where(on_campus=>true)
    # 9           1          0            0           1         | where(on_campus=>true, is_mobile=>false)
    # 10          1          0            1           0         | where(on_campus=>true, is_mobile=>true)
    # 11          1          0            1           1         | INVALID (isMobile & notMobile asserted)
    # 12          1          1            0           0         | INVALID (onCampus & offCampus asserted)
    # 13          1          1            0           1         | INVALID (onCampus & offCampus asserted)
    # 14          1          1            1           0         | INVALID (onCampus & offCampus asserted)
    # 15          1          1            1           1         | INVALID (onCampus & offCampus asserted)
    # Thus, the integer filterCase, which corresponds to the rowNumber, can be formed by converting 4 bit
    # binary term formed by the concatenation {onCampus, offCampus, isMobile, notMobile} into an integer.
    # Note: This filtering cannot be obtained by passing two boolean values (one for on_campus and one for is_mobile)
    # as this would fail to account for cases where no filter is applied to one variable (ie. where we don't care about
    # either location or device)
    def data_sessions_overview
      onCampus = params[:onCampus] ? params[:onCampus].to_i : 0
      offCampus = params[:offCampus] ? params[:offCampus].to_i : 0
      isMobile = params[:isMobile] ? params[:isMobile].to_i : 0
      notMobile = params[:notMobile] ? params[:notMobile].to_i : 0
      filterCase = (2**3)*onCampus + (2**2)*offCampus + (2**1)*isMobile + notMobile

      case filterCase
      when 1 #mobile=f
        sessions = Session.where(@range).where(:is_mobile => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      when 2 #mobile=t
        sessions = Session.where(@range).where(:is_mobile => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      when 4 #campus=f
        sessions = Session.where(@range).where(:on_campus => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      when 5 #campus=f, mobile=f
        sessions = Session.where(@range).where(:on_campus => false, :is_mobile => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      when 6 #campus=f, mobile=t
        sessions = Session.where(@range).where(:on_campus => false, :is_mobile => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      when 8 #campus=t
        sessions = Session.where(@range).where(:on_campus => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      when 9 #campus=t, mobile=f
        sessions = Session.where(@range).where(:on_campus => true, :is_mobile => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      when 10 #campus=t, mobile=t
        sessions = Session.where(@range).where(:on_campus => true, :is_mobile => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      else
        sessions = Session.where(@range).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      end

      @result = process_time_query(sessions)
    end

    def data_sessions_location
      use_perc = params[:use_perc]=="true" ? true : false
      sessions_on = Session.where(@range).where(:on_campus => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      sessions_off = Session.where(@range).where(:on_campus => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)

      @result = process_stacked_time_query(sessions_on, sessions_off, use_perc)
    end

    def data_sessions_device
      use_perc = params[:use_perc]=="true" ? true : false
      sessions_on = Session.where(@range).where(:is_mobile => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      sessions_off = Session.where(@range).where(:is_mobile => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)

      @result = process_stacked_time_query(sessions_on, sessions_off, use_perc)
    end

    def process_time_query(query)
      sub = []
      query.each do |date , count|
        row = { "date" => date ,
                "count" => count}
        sub << row
      end
      return sub
    end

    def process_stacked_time_query(query1, query2, use_perc)
      sub = []
      query1.each do |date , count1|
        count2 = query2[date] ? query2[date] : 0
        row = { "date" => date ,
                "on" => use_perc ? count1.to_f/(count1+count2) : count1,
                "off" => use_perc ? count2.to_f/(count1+count2) : count2}
        sub << row
      end
      return sub
    end

    def process_module_result_query(query, keyHeading, parent, num_results, total_clicks)
      sub = []
      query.to_a[0..num_results-1].each_with_index do |d, i|
        label = d[0]
        count = d[1]
        row = {"rank" => i+1,
               "label" => (label.blank? ? "(blank)"  : label),
               "clickcount" => count,
               "percentage" => ((100.0*count)/total_clicks).round(2),
               "parent" => parent,
               "expanded" => 0,
               "key" => keyHeading + (label.blank? ? "(blank)"  : label) + parent.to_s}
        sub << row
      end
      return sub
    end

    def process_spelling_best_bets_query(serves, clicks, keyHeading, parent, num_results)
      sub = []
      serves.to_a[0..num_results-1].each_with_index do |d , i|
        label = d[0]
        serve_count = d[1]
        click_count = clicks[label] ? clicks[label] : 0
        row = {"rank" => i+1,
               "label" => label,
               "serves" => serve_count,
               "clicks" =>  click_count,
               "ratio" => (100.0*click_count/serve_count).round(2),
               "parent" => parent,
               "expanded" => 0,
               "key" => keyHeading + label + parent.to_s}
        sub << row
      end
      return sub
    end

    def process_searches_query(searches, num_results, total_searches)
      sub = []
      last_row = {}
      searches.to_a[0..num_results-1].each_with_index do |d, i|
        query = d[0]
        count = d[1]
        if (last_row=={}) 
          last_cum_percentage = 0
        else 
          last_cum_percentage = last_row["cum_perc"]
        end
        row = {"rank" => i+1,
               "label" => query,
               "count" => count,
               "percentage" => ((100.0*count)/total_searches).round(2),
               "cum_perc" => (last_cum_percentage + ((100.0*count)/total_searches)),
               "cum_percentage" => (last_cum_percentage + ((100.0*count)/total_searches)).round(2),
               "key" => "top_search" + query}
        sub << row
        last_row = row
      end
      return sub
    end

    def render_data
      respond_to do |format|
        format.json {
          render :json => @result
        }
      end
    end

    def index
      @page_title = 'Search Statistics'

      @table_result = data_general_table

      @total_clicks = @table_result[0]["clicks"].to_f
      @total_searches = @table_result[1]["searches"].to_f
      @total_sessions = @table_result[2]["sessions"].to_f

      @clicks_per_day = (@total_clicks/(@days_in_sample.to_f)).round(4)
      @clicks_per_click = (@total_clicks/@total_clicks).round(0)
      @clicks_per_search = (@total_clicks/@total_searches).round(4)
      @clicks_per_session = (@total_clicks/@total_sessions).round(4)

      @searches_per_day = (@total_searches/(@days_in_sample.to_f)).round(4)
      @searches_per_click = (@total_searches/@total_clicks).round(4)
      @searches_per_search = (@total_searches/@total_searches).round(0)
      @searches_per_session = (@total_searches/@total_sessions).round(4)

      @sessions_per_day = (@total_sessions/(@days_in_sample.to_f)).round(4)
      @sessions_per_click = (@total_sessions/@total_clicks).round(4)
      @sessions_per_search = (@total_sessions/@total_searches).round(4)
      @sessions_per_session = (@total_sessions/@total_sessions).round(0)

      @graph_result = data_general_statistics 

      @clicks_spec = {
        "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
        "data": {
          "name": "clicks",
          "values": @graph_result[0]
          },
        "title": {
          "text": "Clicks",
          "anchor": "middle"},
        "vconcat": [{
          "width": 800,
          "height": 600,
          "mark": "area",
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal",
              "scale": {"domain": {"param": "brush"}},
              "axis": {"title": ""}
            },
            "y": {"field": "count", "type": "quantitative"}
          }
        }, {
          "width": 800,
          "height": 120,
          "mark": "area",
          "params": [{
            "name": "brush",
            "select": {"type": "interval", "encodings": ["x"]}
          }],
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal"
            },
            "y": {
              "field": "count",
              "type": "quantitative",
              "axis": {"tickCount": 3, "grid": false}
            }
          }
        }]
      }

      @searches_spec = {
        "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
        "data": {
          "name": "searches",
          "values": @graph_result[1]
          },
        "title": {
          "text": "Searches",
          "anchor": "middle"},
        "vconcat": [{
          "width": 800,
          "height": 600,
          "mark": "area",
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal",
              "scale": {"domain": {"param": "brush"}},
              "axis": {"title": ""}
            },
            "y": {"field": "count", "type": "quantitative"}
          }
        }, {
          "width": 800,
          "height": 120,
          "mark": "area",
          "params": [{
            "name": "brush",
            "select": {"type": "interval", "encodings": ["x"]}
          }],
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal"
            },
            "y": {
              "field": "count",
              "type": "quantitative",
              "axis": {"tickCount": 3, "grid": false}
            }
          }
        }]
      }

      @sessions_spec = {
        "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
        "data": {
          "name": "sessions",
          "values": @graph_result[2]
          },
        "title": {
          "text": "Sessions",
          "anchor": "middle"},
        "vconcat": [{
          "width": 800,
          "height": 600,
          "mark": "area",
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal",
              "scale": {"domain": {"param": "brush"}},
              "axis": {"title": ""}
            },
            "y": {"field": "count", "type": "quantitative"}
          }
        }, {
          "width": 800,
          "height": 120,
          "mark": "area",
          "params": [{
            "name": "brush",
            "select": {"type": "interval", "encodings": ["x"]}
          }],
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal"
            },
            "y": {
              "field": "count",
              "type": "quantitative",
              "axis": {"tickCount": 3, "grid": false}
            }
          }
        }]
      }
    end

    def clicks_overview
      @page_title = 'Clicks Overview'

      @modules_clicked = data_module_clicks

      @guides_clicked = data_result_clicks

      @clicks_modules_spec = 
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "description": "Pie Chart with percentage_tooltip",
          "title": "Clicks Overview",
          "data": {
            "values": @modules_clicked
          },
          "mark": {"type": "arc", "tooltip": true},
          "encoding": {
            "theta": {"field": "clickcount", "type": "quantitative", "stack": "normalize"},
            "color": {"field": "label", "type": "nominal"}
          },
          "width": 800, 
          "height": 600
        }
      @clicks_guides_spec = 
        {
          "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
          "description": "Pie Chart with percentage_tooltip",
          "title": "Modules Overview",
          "data": {
            "values": @guides_clicked
          },
          "mark": {"type": "arc", "tooltip": true},
          "encoding": {
            "theta": {"field": "clickcount", "type": "quantitative", "stack": "normalize"},
            "color": {"field": "label", "type": "nominal"}
          },
          "width": 800, 
          "height": 600
        }
    end

    def top_searches
      @page_title = 'Top Searches'

      @top_searches = data_top_searches
    end

    def top_spot
      @page_title = params[:ga_top_spot_module]

      @spelling_suggestion  = data_spelling_suggestions
      @best_bets_reg = data_best_bets(@page_title)

      # puts '######################################'
      # puts @best_bets_reg 
      # puts @page_title
    end

    def sessions_overview
      @page_title = 'Sessions Overview'

      @sessions_data = data_sessions_overview

      @sessions_spec = {
        "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
        "data": {
          "name": "sessions",
          "values": @sessions_data
          },
        "title": {
          "text": "Sessions Overview",
          "anchor": "middle"},
        "vconcat": [{
          "width": 800,
          "height": 600,
          "mark": "area",
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal",
              "scale": {"domain": {"param": "brush"}},
              "axis": {"title": ""}
            },
            "y": {"field": "count", "type": "quantitative"}
          }
        }, {
          "width": 800,
          "height": 120,
          "mark": "area",
          "params": [{
            "name": "brush",
            "select": {"type": "interval", "encodings": ["x"]}
          }],
          "encoding": {
            "x": {
              "field": "date",
              "type": "temporal"
            },
            "y": {
              "field": "count",
              "type": "quantitative",
              "axis": {"tickCount": 3, "grid": false}
            }
          }
        }]
      }
    end

    def sessions_details
      @page_title = 'Sessions Details'

      @sessions_location = data_sessions_location

      @sessions_device = data_sessions_device

      @location_spec = {
        "data": {
          "values": @sessions_location},
        "title": "Sessions Location",
        "layer": [
          {
            "width": 800,
            "height": 600,
            "mark": {"type": "area", "color": "#3887c0"},
            "encoding": {
              "x": {"field": "date", "type": "temporal"},
              "y": {"field": "on", "type": "quantitative"},
            }
          },
          {
            "width": 800,
            "height": 600,
            "mark": {"type": "area", "color": "#86bcdc", "opacity": 0.4},
            "encoding": {
              "x": {"field": "date", "type": "temporal"},
              "y": {"field": "off", "type": "quantitative"},
            }
          }
        ]
      }

      @location_spec = {
        "data": {
          "values": @sessions_location},
        "title": "Sessions Location",
        "layer": [
          {
            "width": 800,
            "height": 600,
            "mark": {"type": "area", "color": "#3887c0"},
            "encoding": {
              "x": {"field": "date", "type": "temporal"},
              "y": {"field": "on", "type": "quantitative"},
            }
          },
          {
            "width": 800,
            "height": 600,
            "mark": {"type": "area", "color": "#86bcdc", "opacity": 0.4},
            "encoding": {
              "x": {"field": "date", "type": "temporal"},
              "y": {"field": "off", "type": "quantitative"},
            }
          }
        ]
      }

      #some combo of a horizon graph and the interactive area chart might reproduce what's currently in production? https://vega.github.io/vega-lite/examples/interactive_overview_detail.html, https://vega.github.io/vega-lite/examples/area_horizon.html
      #or just simple layering: https://vega.github.io/vega-lite/docs/layer.html
    end

    def convert_to_time(date_input)
      Time.strptime(date_input, "%m/%d/%Y")
    end

    def days_in_sample
      @days_in_sample = ((@end_date - @start_date) / (24*60*60)).round
      if @days_in_sample < 1
        @days_in_sample = 1
      end

    end

    def get_dates
      start = params[:start_date]
      stop = params[:end_date]
      puts start
      if (!start.blank?)
        @start_date = convert_to_time(start)
      else
        @start_date = Time.current - 180.days
      end
      if (!stop.blank?)
        @end_date = convert_to_time(stop)
      else
        @end_date = Time.current
      end
      @range = { :created_at => @start_date..@end_date }
    end

    def excluded_categories
      "category <> \"common-searches\" AND category <> \"result-types\"AND category <> \"typeahead\""
    end

  end
end
