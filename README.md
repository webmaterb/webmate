# Webmate

Real-time web applications framework in Ruby, based on WebSockets and EventMachine.

## Quick start

#### 1. Install Webmate gem

    $ gem install webmate

#### 2. Run Webmate server

    $ webmate server

#### 3. Run Webmate console

    $ webmate console

#### 4. Show available routes

    $ rake routes

## Tutorial

[Webmate Application Skeleton](https://github.com/webmaterb/webmate-app-skeleton)

### Skeleton

Gemfile

    gem 'webmate'
    gem 'slim'
    gem 'sass', group: assets
    gem 'rake'
    gem 'webmate-sprockets'

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

#### 1. Adding routes

    # app/routes/homepage_routes.rb
    ExampleApp.define_routes do
      get '/', to: 'pages#index', transport: [:http]
    end

#### 2. Adding  responder for this route
    # app/responders/base_reponder.rb
    class BaseResponder < Webmate::Responders::Base
      # Available options
      # before_filter :do_something

      rescue_from Webmate::Responders::ActionNotFound do
        render_not_found
      end
    end

    # app/responders/pages_reponder.rb
    class PagesResponder < BaseResponder
      include Webmate::Responders::Templates

      def index
        slim :index, layout: 'application'
      end
    end

    # app/views/layouts/application.html.slim

    div
      == yield

    # app/views/pages/index.html.slim

    Hello World!

#### 3. MongoDB connection

    # config/mongoid.yml
    development:
      sessions:
        default:
          database: deex_example
          hosts:
            - localhost:27017

    # config/initializers/mongoid.rb
    Mongoid.load!(File.join(WEBMATE_ROOT, 'config', 'mongoid.yml'))

#### 4. Models

    # app/models/project.rb
    class Project
      include Mongoid::Document

      field :name
      field :description
      field :status
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Licenced under [MIT](http://www.opensource.org/licenses/mit-license.php).

## Thanks for using Webmate!

Hope, you'll enjoy Webmate!

Cheers, [Droid Labs](http://droidlabs.pro).
