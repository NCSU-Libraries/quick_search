module QuickSearch::ApplicationHelper
  include QuickSearch::EncodeUtf8

  def application_name
    if action_name == "website"
      I18n.t "website_search.title_name"
    else
      I18n.t "defaults_search.title_name"
    end
  end

  def organization_name
    I18n.t 'organization_name'
  end

  def sanitized_query
    params_q_scrubbed.nil? || params_q_scrubbed == "" ? "" : sanitize(params_q_scrubbed)
  end

  def display_query
    params_q_scrubbed.nil? || params_q_scrubbed == "" ? "" : truncate(params_q_scrubbed, length: 40, separator: ' ')
  end

  def log_query
    params_q_scrubbed.nil? || params_q_scrubbed == "" ? "" : truncate(sanitize(params_q_scrubbed), length: 100, separator: ' ')
  end

  def title(page_title = nil)
    query = params_q_scrubbed.nil? || params_q_scrubbed == "" ? "" : truncate(params_q_scrubbed, length: 40, separator: ' ', escape: false)
    page_title ||= ''
    page_title << "#{query} |" unless query.blank?
    page_title << " #{application_name} |" unless application_name.blank?
    page_title << " #{organization_name}" unless organization_name.blank?

    content_for :title, page_title
  end

  # FIXME this should use en definitions
  def pages(page)
    format_pages ||= ''
    if page.count('-') > 0
      format_pages << "pp.&nbsp;"
    else
      format_pages << "p.&nbsp;"
    end
    format_pages << page
  end

  def render_module(searcher, service_name, partial_name = '/quick_search/search/module', per_page = 3)
    # if there's a custom view available for this searcher, use it
    if lookup_context.exists?("/quick_search/#{service_name}/module", [], true)
      render partial: "/quick_search/#{service_name}/module", locals: { module_display_name: t("#{service_name}_search.display_name"), searcher: searcher, search: '', service_name: service_name, per_page: per_page }
    else
      render partial: partial_name , locals: { module_display_name: t("#{service_name}_search.display_name"), searcher: searcher, search: '', service_name: service_name, per_page: per_page }
    end
  end

  def get_best_bets_data(best_bets_searcher)
    best_bets = {}
    best_bets[:id] = best_bets_searcher.results.first.id
    best_bets[:title] = best_bets_searcher.results.first.title
    best_bets[:link] = best_bets_searcher.results.first.link
    best_bets[:description] = best_bets_searcher.results.first.description
    best_bets[:best_bets_type] = best_bets_searcher.results.first.best_bets_type

    best_bets
  end

 def body_class
    [controller_name, action_name].join('-')
  end

end
