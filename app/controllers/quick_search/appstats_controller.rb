module QuickSearch
  class AppstatsController < ApplicationController
    include Auth

    before_action :get_dates, :days_in_sample
    before_action :auth unless Rails.env.development?

    def data_general_statistics
      @result = []

      clicks = Event.where(@range).where(:action => 'click').group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      @result << process_time_query(clicks)

      sessions = Session.where(@range).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      @result << process_time_query(sessions)

      searches = Search.where(@range).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      @result << process_time_query(searches)

      render_data
    end

    def data_general_table
      @result = []

      @result << { "clicks" => Event.where(@range).where(:action => 'click').count }
      @result << { "searches" => Search.where(@range).count }
      @result << { "sessions" => Session.where(@range).count }

      render_data
    end

    def data_module_clicks
      clicks = Event.where(@range).where(excluded_categories).where(:action => 'click').group(:category).order("count_category DESC").count(:category)
      total_clicks = clicks.values.sum

      @result = process_module_result_query(clicks, "module", 0, 100, total_clicks)

      render_data
    end

    def data_result_clicks
      clicks = Event.where(@range).where(:category => "result-types").where(:action => 'click').group(:item).order("count_item DESC").count(:item)
      total_clicks = clicks.values.sum

      @result = process_module_result_query(clicks, "result", 0, 100, total_clicks)

      render_data
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

      @result = process_searches_query(searches, num_results, total_searches)

      render_data
    end

    def data_spelling_suggestions
      num_results = params[:num_results] ? params[:num_results].to_i : 20
      serves = Event.where(@range).where(:category => "spelling-suggestion", :action => 'serve').group(:item).order("count_category DESC").count(:category)
      clicks = Event.where(@range).where(:category => "spelling-suggestion", :action => 'click').group(:item).count(:category)

      @result = process_spelling_best_bets_query(serves, clicks, "spelling_suggestion", 0, num_results)

      render_data
    end

    def data_spelling_details
      item = params[:item]
      serves = Event.where(@range).where(:category => "spelling-suggestion", :action => 'serve', :item => item).group(:query).order("count_query DESC").count(:query)
      clicks = Event.where(@range).where(:category => "spelling-suggestion", :action => 'click', :item => item).group(:query).count(:query)

      @result = process_spelling_best_bets_query(serves, clicks, "spelling_details", item, 15)

      render_data
    end

    def data_best_bets
      num_results = params[:num_results] ? params[:num_results].to_i : 20
      serves = Event.where(@range).where(:category => "best-bets-regular", :action => 'serve').group(:item).order("count_category DESC").count(:category)
      clicks = Event.where(@range).where(:category => "best-bets-regular", :action => 'click').group(:item).count(:category)

      @result = process_spelling_best_bets_query(serves, clicks, "best_bet", 0, num_results)

      render_data
    end

    def data_best_bets_details
      item = params[:item]
      serves = Event.where(@range).where(:category => "best-bets-regular", :action => 'serve', :item => item).group(:query).order("count_query DESC").count(:query)
      clicks = Event.where(@range).where(:category => "best-bets-regular", :action => 'click', :item => item).group(:query).count(:query)

      @result = process_spelling_best_bets_query(serves, clicks, "best_bet_details", item, 15)

      render_data
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

      render_data
    end

    def data_sessions_location
      use_perc = params[:use_perc]=="true" ? true : false
      sessions_on = Session.where(@range).where(:on_campus => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      sessions_off = Session.where(@range).where(:on_campus => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)

      @result = process_stacked_time_query(sessions_on, sessions_off, use_perc)
      
      render_data
    end

    def data_sessions_device
      use_perc = params[:use_perc]=="true" ? true : false
      sessions_on = Session.where(@range).where(:is_mobile => true).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)
      sessions_off = Session.where(@range).where(:is_mobile => false).group(:created_at_string).order("created_at_string ASC").count(:created_at_string)

      @result = process_stacked_time_query(sessions_on, sessions_off, use_perc)
      
      render_data
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

      clicks_scope = Event.where(@range).where(action: 'click')
      searches_scope = Search.where(@range)
      sessions_scope = Session.where(@range)

      clicks_total = clicks_scope.count
      searches_total = searches_scope.count
      sessions_total = sessions_scope.count

      sample_days = [@days_in_sample, 1].max.to_f

      @general_totals = {
        clicks: clicks_total,
        searches: searches_total,
        sessions: sessions_total
      }

      @general_daily_average = {
        clicks: (clicks_total / sample_days).round(2),
        searches: (searches_total / sample_days).round(2),
        sessions: (sessions_total / sample_days).round(2)
      }

      @general_trend = [
        {
          name: 'Clicks',
          data: clicks_scope.group(:created_at_string).order('created_at_string ASC').count(:created_at_string)
        },
        {
          name: 'Searches',
          data: searches_scope.group(:created_at_string).order('created_at_string ASC').count(:created_at_string)
        },
        {
          name: 'Sessions',
          data: sessions_scope.group(:created_at_string).order('created_at_string ASC').count(:created_at_string)
        }
      ]

      @general_ratio = [
        ['Clicks / Search', searches_total.positive? ? (clicks_total.to_f / searches_total).round(2) : 0.0],
        ['Searches / Session', sessions_total.positive? ? (searches_total.to_f / sessions_total).round(2) : 0.0],
        ['Clicks / Session', sessions_total.positive? ? (clicks_total.to_f / sessions_total).round(2) : 0.0]
      ]
    end

    def clicks_overview
      @page_title = 'Clicks Overview'
    end

    def top_searches
      @page_title = 'Top Searches'

      report = QuickSearch::TopicSearchReport.new(
        relation: Search.where(page: '/').where(@range),
        limit: top_search_report_limit
      )

      @top_search_terms = report.top_terms_chart_data
      @topic_buckets = report.topic_bucket_chart_data
      @search_volume = report.search_volume_chart_data
      @topic_examples = report.topic_examples
    end

    def top_spot
      @page_title = params[:ga_top_spot_module]

      report = QuickSearch::SpotPerformanceReport.new(
        category: @page_title,
        range: @range,
        limit: top_search_report_limit
      )

      @spot_top_served = report.top_served_chart_data
      @spot_ctr = report.click_through_rate_chart_data
      @spot_volume = report.volume_series_chart_data
      @spot_items = report.item_examples
    end

    def sessions_overview
      @page_title = 'Sessions Overview'
    end

    def sessions_details
      @page_title = 'Sessions Details'
    end

    def convert_to_time(date_input)
      Time.parse(date_input)
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

    def top_search_report_limit
      requested_limit = params[:num_results].to_i
      return 20 unless requested_limit.positive?

      [requested_limit, 50].min
    end

  end
end
