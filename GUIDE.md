#webmate app skeleton
see working example on https://github.com/evgeniypetrov/webmate-app-skeleton

## Quick start

to start application, run
  webmate start  
application will be available on localhost:3000 url

to run irb/console
  webmate console

type webmate without params to know all options

show all available routes [ without assets ]
rake routes k

## Tutorial
### Skeleton
require files

to create file, add following gem to Gemfile

Gemfile
  gem 'webmate'
  gem 'slim'
  gem 'sass', group: assets
  gem 'alphasights-sinatra-sprockets', require: 'sinatra-sprockets', group: assets

base required files:

config.ru
  require './config/environment'
  if configatron.assets.compile
    map '/assets' do
      run Sinatra::Sprockets.environment
    end
  end
  run ExampleApp

config/config.rb
  Webmate::Application.configure do |config|
    # add directory to application load paths
    #config.app.load_paths << ["app/uploaders"]
    config.app.cache_classes = true
    config.assets.compile = false

    config.websockets.namespace = 'api'
    config.websockets.enabled = true
    config.websockets.port = 9020
  end

Webmate::Application.configure(:development) do |config|
  config.app.cache_classes = false
  config.assets.compile = true
  config.websockets.port = 3503
end

config/application.rb
  require 'digest/sha1'
  require 'base64'

  class ExampleApp < Webmate::Application
    # do other things)
  end

config/environment.rb
  WEBMATE_ROOT = File.expand_path('.')
  require 'webmate'

  Dir[File.join(WEBMATE_ROOT, 'app', 'routes', '**', '*.rb')].each do |file|
    require file
  end

### Hello world
  adding route
    app/routes/facade_routes.rb
      ExampleApp.define_routes do
        get '/', to: 'pages#index', transport: [:http]
      end

  adding  responder to this route
  create files in app/responders
    base_responder
      class BaseResponder < Webmate::Responders::Base
        # Available options
        # before_filter :do_something

        rescue_from Webmate::Responders::ActionNotFound do
          render_not_found
        end
      end

    pages_responder
      class PagesResponder < BaseResponder
        include Webmate::Responders::Templates

        def index
          slim :index, layout: 'application'
        end
      end

    also, required files
      app/views/layouts/application.html.slim
      app/views/pages/index.html.slim

### Assets
  assets will be searched in app/assets folder, so place them to
  app/assets/javascripts
  app/assets/stylesheets

### Utilities - rake task, scripts
  Rakefile
    require File.expand_path('../config/environment', __FILE__)
    Webmate::Application.load_tasks
