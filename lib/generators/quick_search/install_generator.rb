module QuickSearch
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      desc 'insert routes'
      def insert_routes
        routes = <<-ROUTES
  mount QuickSearch::Engine => "/"
ROUTES
        insert_into_file "config/routes.rb", routes, :after => "Rails.application.routes.draw do\n"
      end


      desc 'insert generic theme'
      def insert_theme

        theme_gem_entry = <<-THEME
\n
# -Inserted by QuickSearch-

# QuickSearch theme
#
# Remove the following if you want to use a different theme

gem 'quick_search-generic_theme'

# END -Inserted by QuickSearch-

THEME


        say("\nYou'll need to include a theme which QuickSearch uses to render your results. We've built a generic
theme which can be modified or extended to meet your needs. Alternatively you can build your own from
scratch and include it.\n\n")

        @theme_response = ask("Would you like to install the generic theme?", limited_to: ['y', 'n'])

        if @theme_response == 'y'
          insert_into_file "Gemfile", theme_gem_entry, :after => /gem [\"\']quick_search-core[\"\'].*$/
        end

      end


      desc 'insert searchers'
      def insert_searchers
        searcher_gem_entry = <<-SEARCHERS
\n
# -Inserted by QuickSearch-

# QuickSearch searchers
#
# If you want to use different searchers, remove/replace these and be sure to remove them from
# your config/quick_search_config.yml file as well as references to them in your theme's search
# results page template

gem 'quick_search-wikipedia_searcher', :git => 'https://github.com/samirlalvani/quick_search-wikipedia_searcher.git'
gem 'quick_search-open_library_searcher', :git => 'https://github.com/samirlalvani/quick_search-open_library_searcher.git'
gem 'quick_search-arxiv_searcher', :git => 'https://github.com/samirlalvani/quick_search-arxiv_searcher.git'
gem 'quick_search-placeholder_searcher', :git => 'https://github.com/samirlalvani/quick_search-placeholder_searcher.git'

# -END Inserted by QuickSearch-

        SEARCHERS

        say("\nTo have a working application you'll need to install some searchers. Searchers are the
code that integrates with third-party APIs, handles performing searches and creating results objects.
By default quick_search-core provides no searchers. Some searchers are available and it is easy to
write your own.\n\n")


        @searcher_response = ask("Would you like to install some basic searchers that do not require API keys?", limited_to: ['y', 'n'])

        if @searcher_response == 'y'
          insert_into_file "Gemfile", searcher_gem_entry, :after => /gem [\"\']quick_search-core[\"\'].*$/
        end

      end


      desc 'bundle install theme/searchers'
      def bundle_install_theme_searchers
        Bundler.with_clean_env do
          run "bundle install"
        end
      end

      desc 'create application configuration file'
      def quick_search_config_yml
        copy_file 'quick_search_config.yml', 'config/quick_search_config.yml'
      end

      desc 'update quick_search_config.yml'
      def update_quick_search_config
        if @theme_response == 'y'
          theme_config = 'quick_search_generic_theme'
          insert_into_file "config/quick_search_config.yml", theme_config, :after => /^  theme: '/
        end
        if @searcher_response == 'y'
          included_searchers = ',arxiv,open_library,wikipedia,placeholder'
          included_found_types = 'arxiv,open_library,wikipedia,placeholder,placeholder,placeholder,placeholder'
          insert_into_file "config/quick_search_config.yml", included_searchers, :after => /^  searchers: \[best_bets/
          insert_into_file "config/quick_search_config.yml", included_found_types, :after => /^  found_types: \[/
        end
      end

      desc 'create best bets configuration file'
      def best_bets_yml
        copy_file 'best_bets.yml', 'config/best_bets.yml'
      end

      desc 'create kaminari initializer'
      def kaminari_initializer
        copy_file 'kaminari.rb', 'config/initializers/kaminari.rb'
      end

      desc 'add styles'
      def add_styles
        remove_file 'app/assets/stylesheets/application.css'
        create_file 'app/assets/stylesheets/application.css.scss', %Q|@import "quick_search";\n|
      end

      desc 'add javascript'
      def add_javascript
        gsub_file('app/assets/javascripts/application.js', '//= require_tree .', '//= require quick_search')
      end

      desc 'install migrations'
      def install_migrations
        rake "quick_search:install:migrations"
        rake "db:migrate"
      end

      desc 'display messages about what needs to be configured'
      def configuration_messages
        say "QuickSearch installation complete.\n\n", :green
        if @searcher_response == 'y'
          say "We've installed a set of default searchers.\n", :green
        end
        if @theme_response == 'y'
          say "We've installed the generic theme.\n", :green
        end
        file = File.read(File.join( File.expand_path('../templates', __FILE__), 'post_install.txt'))
        say file, :green
      end

    end
  end
end
