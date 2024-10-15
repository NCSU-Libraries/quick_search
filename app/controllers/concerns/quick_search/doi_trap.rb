module QuickSearch::DoiTrap
  extend ActiveSupport::Concern

  include QuickSearch::EncodeUtf8

  private

  def doi_trap
    unless params_q_scrubbed.nil?
      if is_a_doi?(doi_query)
        Event.create(category: 'doi-trap', query: doi_query, action: 'click')
        redirect_to doi_loaded_link, allow_other_host: true
        # Alternately insert a loaded link into the results interface
        # @doi_loaded_link = loaded_link
        # @doi_callout = "Searching for a DOI? Try this: "
      end
    end
  end

  def is_a_doi?(query)
    if doi_regex.match(query)
      true
    else
      false
    end
  end

  def doi_regex
    /^(?:(?:doi:?\s*|(?:http:\/\/)?(?:dx\.)?(?:doi\.org)?\/))?(10(?:\.\d+){1,2}\/\S+)$/i
  end

  def doi_loaded_link
    QuickSearch::Engine::APP_CONFIG['doi_loaded_link'] + CGI.escape(doi_regex.match(doi_query)[1])
  end

  def doi_query
    query = params_q_scrubbed
    query = query.gsub('https://', '').gsub('http://', '')
    query.strip!
    query.squish!
    query
  end

end
