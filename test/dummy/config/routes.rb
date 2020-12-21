Rails.application.routes.draw do

  mount QuickSearch::Engine => "/"

  root :to => 'quick_search/search#index'
  get 'xhr_search' => 'quick_search/search#xhr_search', :defaults => { :format => 'html' }
end
