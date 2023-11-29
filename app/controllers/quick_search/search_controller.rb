module QuickSearch
  class SearchController < ApplicationController
    include QuickSearch::SearcherConcern
    include QuickSearch::DoiTrap
    include QuickSearch::OnCampus
    include QuickSearch::QueryParser
    include QuickSearch::EncodeUtf8
    include QuickSearch::QueryFilter
    include QuickSearch::SearcherConfig
    include QuickSearch::SearchHelper

    require 'benchmark_logger'

    before_action :doi_trap, :log_query
    after_action :realtime_message, only: [:index]
    helper_method :all_good_bets
    def index
      loaded_searches
      @common_searches = common_searches
      http_search
    end

    def get_link_field(elemdict)
      url = ''
      if elemdict[:link]
        url = strip_character(elemdict[:link], '/')
      elsif elemdict[:url]
        url = strip_character(elemdict[:url], '/')
      end
      url
    end

    def all_good_bets
      good_bets = []
      best_bet_links = []
      if !@best_bets.is_a?(QuickSearch::SearcherError)
        best_bet_links = @best_bets.results.flatten.map{|elem|get_link_field(elem)}
      end
      items = QuickSearch::Engine::APP_CONFIG['good_bets_searchers'].present? ? QuickSearch::Engine::APP_CONFIG['good_bets_searchers'] : []
      items.each do |item|
        item = instance_variable_get("@#{item}")
        if !item.is_a?(QuickSearch::SearcherError)
          filtered_good_bets = item.good_bets.select{|gb|!best_bet_links.include?(strip_character(gb[:link], '/'))}
          gblinks = good_bets.map{|elem|elem[:link]}
          filtered_good_bets.each do |fgb|
            unless gblinks.include?(fgb[:link]) || fgb[:notgoodbet]
              matchpattern = Regexp.new(Regexp.escape(@query.split(" ").join("|")), Regexp::IGNORECASE)
              fgb[:title] = fgb[:title].gsub(matchpattern) { |match| "<b>#{match}</b>" }
              fgb[:isgoodbet] = true
              fgb[:description] = fgb[:description] ? fgb[:description].gsub(matchpattern) { |match| "<b>#{match}</b>" } : ""
              good_bets.push(OpenStruct.new(fgb))
            end
          end
        end
      end
      return good_bets
    end

    # TODO: throw error if required files not in place
    def single_searcher
      searcher_name = params[:searcher_name]

      searcher_cfg = searcher_config(searcher_name)
      if searcher_cfg and searcher_cfg.has_key? 'loaded_searches'
        additional_services = Array.new(searcher_cfg['loaded_searches'])
      else
        additional_services = []
      end
      loaded_searches(additional_services)

      @common_searches = []
      if searcher_cfg and searcher_cfg.has_key? 'common_searches'
        @common_searches = searcher_cfg['common_searches']
      end

      #TODO: maybe a default template for single-searcher searches?
      http_search(searcher_name, "quick_search/search/#{searcher_name}_search")
    end

    # The following searches for individual sections of the page.
    # This allows us to do client-side requests in cases where the original server-side
    # request times out or otherwise fails.
    def xhr_search
      endpoint = params[:endpoint]

      if params[:template] == 'with_paging'
        template = 'xhr_response_with_paging'
      else
        template = 'xhr_response'
      end

      @query = params_q_scrubbed
      @page = page
      @per_page = per_page(endpoint)
      @offset = offset(@page,@per_page)

      http_client = HTTPClient.new
      update_searcher_timeout(http_client, endpoint, true)

      benchmark "%s xhr #{endpoint}" % CGI.escape(@query.to_str) do

        klass = "QuickSearch::#{endpoint.camelize}Searcher".constantize
        searcher = klass.new(http_client,
                             extracted_query(params_q_scrubbed),
                             @per_page,
                             @offset,
                             @page,
                             on_campus?(ip),
                             extracted_scope(params_q_scrubbed))
        searcher.search

        searcher_partials = {}
        searcher_cfg = searcher_config(endpoint)
        unless searcher_cfg.blank?
          services = searcher_cfg['services'].blank? ? [] : searcher_cfg['services']
        else
          services = []
        end
        services << endpoint

        respond_to do |format|

          format.html {
            services.each do |service|
              service_template = render_to_string(
                :partial => "quick_search/search/#{template}",
                :layout => false,
                :locals => { module_display_name: t("#{endpoint}_search.display_name"),
                             searcher: searcher,
                             search: '',
                             service_name: service
                            })
              searcher_partials[service] = service_template
            end
            render :json => searcher_partials
          }

          format.json {

            # prevents openstruct object from results being nested inside tables
            # See: http://stackoverflow.com/questions/7835047/collecting-hashes-into-openstruct-creates-table-entry
            result_list = []
            searcher.results.each do |result|
              result_list << result.to_h
            end

            render :json => { :endpoint => endpoint,
                              :per_page => @per_page.to_s,
                              :page => @page.to_s,
                              :total => searcher.total,
                              :results => result_list
            }
          }
        end
      end
    end

    private

    def http_search(endpoint = 'defaults', page_to_render = :index)
      @ip = request.remote_ip
      @search_form_placeholder = I18n.t "#{endpoint}_search.search_form_placeholder"
      @page_title = I18n.t "#{endpoint}_search.display_name"
      @module_callout = I18n.t "#{endpoint}_search.module_callout"
      @spell_check = spell_check(params_q_scrubbed)
      if search_in_params?
        @query = params_q_scrubbed
        @search_in_params = true
        search_all_in_threads(endpoint)
        #log_search(@query, page_to_render)
        render page_to_render
      else
        @search_in_params = false
        render '/quick_search/pages/home'
      end
    end

    def page
      if page_in_params?
        page = params[:page].to_i
      else
        page = 1
      end
      page
    end
    helper_method :page

    def per_page(endpoint)
      searcher_cfg = searcher_config(endpoint)
      if params[:per_page]
        per_page = params[:per_page].to_i
      elsif params[:template] == 'with_paging'
        if searcher_cfg and searcher_cfg.has_key? 'with_paging'
          per_page = searcher_cfg['with_paging']['per_page']
        else
          per_page = 10
        end
      else
        per_page = QuickSearch::Engine::APP_CONFIG['per_page']
      end

      if per_page > QuickSearch::Engine::APP_CONFIG['max_per_page']
        per_page = QuickSearch::Engine::APP_CONFIG['max_per_page']
      end

      per_page
    end

    def offset(page, per_page)
      if page != 0
        (page * per_page) - per_page
      else
        0
      end
    end

    def page_in_params?
      params[:page] && !params[:page].blank?
    end

    def search_in_params?
      params_q_scrubbed && !params_q_scrubbed.blank?
    end
    helper_method :search_in_params?

    def common_searches
      QuickSearch::Engine::APP_CONFIG['common_searches']
    end

    def loaded_searches(additional_services=[])
      @search_services_for_display = []
      @extracted_query = extracted_query(params_q_scrubbed)
      search_services = additional_services + Array.new(QuickSearch::Engine::APP_CONFIG['loaded_searches'])

      search_services.each do |search_service|
        if search_in_params?
          @search_services_for_display << {'name' => search_service['name'], 'link'=> search_service['query'] + extracted_query(params_q_scrubbed)}
        else
          @search_services_for_display << {'name' => search_service['name'], 'link'=> search_service['landing_page']}
        end
      end
    end

    def realtime_message
      if base_url = QuickSearch::Engine::APP_CONFIG['realtime_url']
        begin
          client = HTTPClient.new
          body = {q: params_q_scrubbed}
          url = File.join(base_url, "/message/quicksearch-#{Rails.env}")
          res = client.post(url, body)
        rescue
        end
      end
    end

    def benchmark(message)
      result = nil
      ms = Benchmark.ms { result = yield }
      BenchmarkLogger.info '%s (%.1fms)' % [ message, ms ]
      result
    end

    # TODO: move this --- is this necessary?
    def log_query
      if search_in_params?
        @log_query = filter_query(params_q_scrubbed)
      else
        @log_query = ""
      end
    end

  end
end
