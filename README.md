# QuickSearch

> Note: This code has recently been converted to a Rails Gem Engine. It is encouraged that you use this version, but if you are
> looking for the original release of QuickSearch as a standalone Rails project, it can be found here:
> https://github.com/NCSU-Libraries/quick_search/tree/pre-gem

[![Build Status](https://travis-ci.org/NCSU-Libraries/quick_search.svg?branch=master)](https://travis-ci.org/NCSU-Libraries/quick_search)
[![Gem Version](https://badge.fury.io/rb/quick_search-core.svg)](https://badge.fury.io/rb/quick_search-core)

QuickSearch is a customized federated search tool designed to connect people to a variety of library resources, services, and tools. QuickSearch is designed to complement and increase use of existing dedicated library resource discovery tools, such as the catalog, electronic resource search, and subject guides/portals, by directing people to them via an intuitive search interface. The aim of QuickSearch is to provide people with a quick and easy way to find the information they need.

For more information about NCSU Libraries' QuickSearch and the history of the project, see: http://www.lib.ncsu.edu/projects/quicksearch

For NCSU Libraries' implementation of QuickSearch, see:
http://search.lib.ncsu.edu

## Features

- Single search with bento-box style results
- Modular
  - swap out searcher modules and themes easily
  - choose from a variety of existing searchers or create your own
- Best Bets
- Search analytics

## Disclaimer

This code has been extracted from the code we have been running in
production, but still should be considered an early release.

## Installation

The aim of QuickSearch is to make it very easy to get up and running.

Follow these instructions to install QuickSearch for
development.

#### Prerequisites

- Rails 5.0
- Ruby 2.2.2+ or 2.3.x
- MySQL development headers (mysql-devel package on CentOS, libmysqlclient-dev on Ubuntu)
- qtwebkit development headers (qtwebkit-devel package on CentOS, libqtwebkit-dev on Ubuntu)

#### Instructions

##### Create a new Rails app, cd into the directory:

    rails new my_app

    ...

    cd my_app

##### Add quick_search-core gem to your Gemfile:

    gem 'quick_search-core'

> For development, use: gem 'quick_search-core', git: 'git://github.com/NCSU-Libraries/quick_search.git'

##### Run 'bundle install'

##### Run the QuickSearch installation generator:

    bundle exec rails generate quick_search:install

The generator will install the generic QuickSearch theme, and some
searchers that will work out of the box. For more information on further
configuring QuickSearch, see: [Configuring QuickSearch](docs/configuration.md)

##### Start the server:

    rails s

##### QuickSearch will be available at http://localhost:3000/

## Documentation

Find more in-depth documentation about QuickSearch in the [docs
directory](docs/README.md)

## Customizing QuickSearch

QuickSearch is built in a modular way, and is easy to modify or extend.
For more in-depth documentation about this, see:

- [Customizing QuickSearch Searchers](docs/customizing_searchers.md)
- [Customizing QuickSearch Themes](docs/customizing_themes.md)

### Searchers

Here are a list of searchers that have been created for QuickSearch so
far. Feel free to submit a pull request to add to this list.

|Searcher                |Line to include in Gemfile to install          |Repository                         |
|------------------------|-----------------------------------------------|-----------------------------------|
|arxiv                   |gem 'quick_search-arxiv_searcher'              |[quick_search-arxiv_searcher](https://www.github.com/ncsu-libraries/quick_search-arxiv_searcher)               |
|wikipedia               |gem 'quick_search-wikipedia_searcher'          |[quick_search-wikipedia_searcher](https://www.github.com/ncsu-libraries/quick_search-wikipedia_searcher)       |
|OpenLibrary             |gem 'quick_search-open_library_searcher'       |[quick_search-open_library_searcher](https://www.github.com/ncsu-libraries/quick_search-open_library_searcher) |
|Placeholder           |gem 'quick_search-placeholder_searcher'       |[quick_search-placeholder_searcher](https://www.github.com/ncsu-libraries/quick_search-placeholder_searcher) |
|Summon                  |gem 'quick_search-summon_searcher'               |[quick_search-summon_searcher](https://www.github.com/ncsu-libraries/quick_search-summon_searcher) |
|NCSU Libraries' Catalog |Coming soon                                    |                                   |
|ContentDM               |gem 'quick_search-contentdm'                   | [quick_search-contentdm](https://github.com/tulibraries/quick_search-contentdm)                       |


### Themes

|Theme          |Line to include in Gemfile to install |Repository                         |
|---------------|--------------------------------------|-----------------------------------|
|Generic Theme  |gem 'quick_search-generic_theme'      |[quick_search-generic_theme](https://www.github.com/ncsu-libraries/quick_search-generic_theme)|


## Running the Tests

In order to run the tests, you'll need to have Xvfb installed. If you
are on CentOS, you can run:

    sudo yum install org-x11-server-Xvfb

On Ubuntu/Debian:

    sudo apt-get install xvfb

To set up the testing database, run:

    RAILS_ENV=test bundle exec rake db:schema:load

Then, to run the tests:

    bundle exec rake test

## TODO

There are still some TODOs left in terms of extracting this code from
our production codebase:

- Improve documentation

## Bugs, Feature Requests, etc.

To report bugs, or request features, please use GitHub issues. We also
welcome pull requests!

## Authors

Here are the people who have contributed code to this implementation of
QuickSearch (listed in alphabetical order)

- Kevin Beswick
- Nushrat Khan
- Cory Lown
- Niqui O'Neill
- Jason Ronallo
- Ryan West

## License

See MIT-LICENSE
