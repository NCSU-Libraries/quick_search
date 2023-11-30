# Configuring QuickSearch

## QuickSearch Configuration Files

There are several configuration files you need to set up after
installing QuickSearch. Here are descriptions for each:

### quick_search_config.yml

This is QuickSearch's main configuration file where you configure
searchers, themes, and set other QuickSearch options. See the
/config/quick_search_config.yml.example for a sample configuration file.

### database.yml

This is a Rails configuration file for database connection information.
QuickSearch uses a database to log statistics for searches, and clicks.

You can find more information on populating this file in the [Rails
documentation for database.yml](http://guides.rubyonrails.org/configuring.html#configuring-a-database)

### secret_token.rb

This file contains a secret key for session verification. It should be
set to a 30+ character value, and a non-dictionary word. For more
information, see the [Rails Documentation](http://guides.rubyonrails.org/v4.1/security.html#session-storage)

## Configuring Themes

QuickSearch themes are implemented as Rails Gem Engines. To change which theme that QuickSearch uses, there are four steps to follow:

- Add the theme gem into your Gemfile
- Change the “theme” key in quick_search_config.yml to your theme’s name
- Run “rake assets:clobber” to clear the Rails cache (otherwise you may get odd results)
- Restart the QuickSearch server

QuickSearch is designed to be modular in terms of its look and feel. A generic base theme is included by default, based on the Foundation CSS framework, where the templates are written in ERB, the stylesheets are SASS. Any part of this base theme can be overridden, for instance if you’d only like to change the colors, or replace the QuickSearch header with your library website headers, etc.

To override a file in a theme, just create your own version of the file
in the corresponding directory in your QuickSearch installation. This is
a good approach if you'd like to only modify smaller parts - otherwise
you would probably want to create your own theme.

If you would like to start from scratch and create your own theme, you are able to do that too. Here are a list of templates that QuickSearch expects to be implemented - other than that, you are able to use whichever technologies you’d like for the front-end (you are not tied to Foundation, or anything else that the generic theme implements).

- app/views/layouts/index.html.erb (the main QuickSearch layout)
- app/views/search/index.html.erb (the search results page)

## Configuring Searchers

In the QuickSearch bento-box layout, each section of the bento-box is referred to as a “searcher”. A searcher is essentially an interface between a service that your library uses (such as your library catalog) and QuickSearch that defines how to search that service, and how to present the results. Searchers are implemented as Rails Gem Engines that can then be included into QuickSearch.

There are a number of searchers that have already been written for QuickSearch, and have been contributed to the community. These can be found here.

To include a searcher in QuickSearch, follow these steps:

- Include your searcher gem in the QuickSearch Gemfile
- Add the searcher name to the “searchers” section in “config/quick_search_config.yml”
- In your theme, you will need to specify where the searcher is rendered. To do this, edit your “app/views/quick_search/search/index.html.erb” file, and include this where you’d like the searcher to be rendered: “render_module(@your_searcher, ‘your_searcher’)”

Normally, searchers require some configuration options to be set -
things like API keys, URL to the service, etc. To override the default
configuration of the searcher, you need to create a configuration file in
the quick_search/config/searchers/ directory called [searcher_name_here]_config.yml.
So if your searcher is called catalog, it would be catalog_config.yml.

You can also [implement your own searcher](customizing_searchers.md) - this usually involves a minimal amount of code, depending on how complex you want it to be.

## Including Stop Words

If there are words you have users search often that are skewing results you can add a stop words field to the config. For example, many of NC State's users will add `ncsu` to a search like they are using google. For many of our bentos we don't want `ncsu` searched. However we feel that `ncsu` is a valid query for our catalog and summon searchers. We can add exceptions. In order to set this up a a stop_words list to your “config/quick_search_config.yml” file. You can also add exceptions in the stop_words_exceptions field. The example below adds the stop_words 'ncsu' and 'test' but tells the application to not remove the word 'ncsu' or 'test' for the catalog and to not remove the word 'ncsu' for summon.

```
stop_words: ['ncsu', 'test']
stop_words_exceptions: {'catalog': ['ncsu', 'test'], 'summon': ['ncsu']}
```