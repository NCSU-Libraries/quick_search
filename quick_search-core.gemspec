$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "quick_search/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "quick_search-core"
  s.version     = QuickSearch::VERSION
  s.authors     = ["Kevin Beswick", "Nushrat Khan", "Cory Lown", "Jason Ronallo"]
  s.email       = ["quicksearch@lists.ncsu.edu"]
  s.homepage    = "http://www.github.com/ncsu-libraries/quick_search"
  s.summary     = "QuickSearch is a toolkit for easily creating custom bento-box search applications"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.required_ruby_version = '>= 2.2.2'

  s.add_dependency "rails", "~> 5.2"
  s.add_dependency 'jquery-rails', '~> 4.3'
  s.add_dependency "kaminari"
  s.add_dependency "nokogiri"
  s.add_dependency "fastimage"
  s.add_dependency "mysql2"
  s.add_dependency "modernizr-rails"
  s.add_dependency "httpclient"
  s.add_dependency "vega"


end
