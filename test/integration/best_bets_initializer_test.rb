require 'test_helper'

class BestBestInitializerTest < ActionDispatch::IntegrationTest
  test 'best bet keyword with dash should be found' do
    # Clear the solr_url so we don't try to get Best Bet from Solr
    QuickSearch::Engine::APP_CONFIG['best_bets']['solr_url'] = ''

    # Keyword for "testbestbet" entry in test/dummy/config/best_bets.yml
    visit xhr_search_path(q: '123-456', endpoint: 'best_bets', format: 'json')

    json = JSON.parse(page.html)
    first_result = json['results'][0]
    assert_equal 'testbestbetdash', first_result['id']
  end
end
