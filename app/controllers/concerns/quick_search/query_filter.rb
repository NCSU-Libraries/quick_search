module QuickSearch::QueryFilter
  extend ActiveSupport::Concern

  include ActionView::Helpers::TextHelper

  private

  def filter_query(query, stop_words=[])
    if query.match(/ -$/)
      query = query.sub(/ -$/,"")
    end
    query.gsub!('*', ' ')
    query.gsub!('!', ' ')
    query.gsub!('-', ' ') # Solr returns an error if multiple dashes appear at start of query string
    query.gsub!('\\', '')
    # query.gsub!('"', '')
    query.strip!
    query.squish!
    query.downcase! # FIXME: Do we really want to downcase everything?
    query = truncate(query, length: 100, separator: ' ', omission: '', escape: false)
    if stop_words && stop_words.length > 0
      query = query.gsub(/(?:[\s]|^)(#{stop_words.join("|")})(?=[\s]|$)/, "")
    end
    query
  end

end
