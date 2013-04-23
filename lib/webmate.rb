ENV["RACK_ENV"] ||= "development"

require "em-synchrony"
require "sinatra"
require "sinatra/cookies"
require "sinatra/reloader"
require "sinatra-websocket"
require 'sinatra_more/markup_plugin'
require "configatron"
require "rack/contrib/post_body_content_type_parser"
require "yajl"

require 'webmate/env'
require 'webmate/application'
require 'webmate/config'
require 'webmate/websockets'
require 'webmate/logger'

require 'bundler'
Bundler.setup
if Webmate.env == 'development'
  Bundler.require(:assets)
end

require 'webmate/views/helpers'
require 'webmate/support/sprockets'
require 'webmate/responders/exceptions'
require 'webmate/responders/abstract'
require 'webmate/responders/base'
require 'webmate/responders/response'
require 'webmate/responders/rendering_scope'
require 'webmate/responders/templates'
require 'webmate/services/base'
require 'webmate/observers/base'
require 'webmate/decorators/base'
require 'webmate/route_helpers/routes_collection'
require 'webmate/route_helpers/route'

Bundler.require(:default, Webmate.env.to_sym)

require 'webmate/socket.io/actions/handshake'
require 'webmate/socket.io/actions/connection'
require 'webmate/socket.io/packets/base'
require 'webmate/socket.io/packets/disconnect'
require 'webmate/socket.io/packets/connect'
require 'webmate/socket.io/packets/heartbeat'
require 'webmate/socket.io/packets/message'
require 'webmate/socket.io/packets/json'
require 'webmate/socket.io/packets/event'
require 'webmate/socket.io/packets/ack'
require 'webmate/socket.io/packets/error'
require 'webmate/socket.io/packets/noop'
require 'webmate/authentication/base'

# it's not correct. app config file should be required by app
file = "#{Webmate.root}/config/config.rb"
require file if FileTest.exists?(file)

configatron.app.load_paths.each do |path|
  Dir[ File.join( Webmate.root, path, '**', '*.rb') ].each do |file|
    class_name = File.basename(file, '.rb')
    eval <<-EOV
      autoload :#{class_name.camelize}, "#{file}"
    EOV
  end
end

# run observers
Dir[ File.join( Webmate.root, 'app', 'observers', '**', '*.rb')].each do |file|
  require file
end

class Webmate::Application
  #register Webmate::RouteHelpers::Channels
  register Sinatra::Reloader
  register SinatraMore::MarkupPlugin

  #helpers Webmate::Views::Helpers
  helpers Sinatra::Cookies
  helpers Sinatra::Sprockets::Helpers

  set :public_path, "#{Webmate.root}/public"
  set :root, Webmate.root
  set :views, Proc.new { File.join(root, 'app', "views") }
  set :reloader, !configatron.app.cache_classes

  # auto-reloading dirs
  also_reload("#{Webmate.root}/config/config.rb")
  also_reload("#{Webmate.root}/config/application.rb")
  configatron.app.load_paths.each do |path|
    also_reload("#{Webmate.root}/#{path}/**/*.rb")
  end

  use Webmate::Logger
  use Rack::PostBodyContentTypeParser
  use Rack::Session::Cookie, key: configatron.cookies.key,
                           domain: configatron.cookies.domain,
                           path: '/',
                           expire_after: 14400,
                           secret: configatron.cookies.secret
end

Sinatra::Sprockets.configure do |config|
  config.app = Webmate::Application
  ['stylesheets', 'javascripts', 'images'].each do |dir|
    # require application assets
    config.append_path(File.join('app', 'assets', dir))
  end
  config.precompile = [ /\w+\.(?!js|css).+/, /application.(css|js)/ ]
  config.compress = configatron.assets.compress
  config.debug = configatron.assets.debug
  config.compile = configatron.assets.compile
  config.digest = configatron.assets.digest
end

path = File.expand_path("#{WEBMATE_ROOT}/config/initializers/*.rb")
Dir[path].each { |initializer| require_relative(initializer) }

# it's not correct. app config file should be required by app
file_path = "#{WEBMATE_ROOT}/config/application.rb"
require file_path if FileTest.exists?(file_path)
