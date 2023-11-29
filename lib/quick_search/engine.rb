module QuickSearch
  class Engine < ::Rails::Engine
    isolate_namespace QuickSearch

    # quick_search initializer
    #
    # We want to load the quick_search_config file, and set the loading order of the view paths as follows:
    # 1. Application which imports gem engine/theme
    # 2. Theme
    # 3. Engine
    #
    # This way, we can make application specific overrides of views, otherwise fall back to theme,
    # and finally fall back to the QS core if needed.

    initializer :quick_search, :after => :add_view_paths do
      config_file = File.join(Rails.root, "/config/quick_search_config.yml")
      if File.exist?(config_file)
        QuickSearch::Engine::APP_CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]
        ActiveSupport.on_load(:action_controller) do
          # get theme / core engine classes
          theme_engine_class = "#{QuickSearch::Engine::APP_CONFIG['theme'].classify}::Engine".constantize
          core_engine_class = "QuickSearch::Engine".constantize

          # get the correct view paths for the application, theme, and engine
          core_view_path = core_engine_class.root.join('app', 'views')
          theme_view_path = theme_engine_class.root.join('app', 'views', QuickSearch::Engine::APP_CONFIG['theme'])
          app_view_path = Rails.root.join('app', 'views')

          # prepend to the existing view path ordering
          prepend_view_path(core_view_path)
          prepend_view_path(theme_view_path)
          prepend_view_path(app_view_path)
        end
      end
    end

    # best_bets initializer
    #
    # Here we set up Best Bets. If there is a solr_url defined in the config, then we don't need to do anything,
    # as Best Bets will be assumed to be in Solr, and the BestBetsSearcher will look there. Otherwise, load the
    # best_bets.yml file into memory, and search that directly. The latter is only recommended for smaller amounts of
    # Best Bets. The reason for this dual approach is that it removes Solr as an absolute requirement for QuickSearch.

    initializer :best_bets, :after => :quick_search do
      if defined? QuickSearch::Engine::APP_CONFIG and QuickSearch::Engine::APP_CONFIG['best_bets']['solr_url'].empty?
        best_bets_file = File.join(Rails.root, "/config/best_bets.yml")

        if File.exist?(best_bets_file)

          # Helper class for enabling access to the "filter_query" method
          # in QuickSearch::QueryFilter concern
          class BestBetFilter
            include QuickSearch::QueryFilter

            def filter(keyword)
              filter_query(keyword)
            end
          end

          best_bet_filter = BestBetFilter.new
          QuickSearch::Engine::BEST_BETS = YAML.load_file(best_bets_file)['best_bets']
          QuickSearch::Engine::BEST_BETS_INDEX = {}
          QuickSearch::Engine::BEST_BETS.each do |best_bet_name, best_bet|
            QuickSearch::Engine::BEST_BETS[best_bet_name]['id'] = best_bet_name
            best_bet['keywords'].each do |keyword|
              # Pass keyword through "filter_query" method so that keyword
              # will match query term passed through the same method
              keyword = best_bet_filter.filter(keyword)
              QuickSearch::Engine::BEST_BETS_INDEX[keyword.downcase] = best_bet_name
            end
          end
        end
      end
    end
  end
end
