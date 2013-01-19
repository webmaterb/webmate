ENV["RACK_ENV"] ||= "development"

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

require 'bundler'
Bundler.setup
Bundler.require(:default, ENV["RACK_ENV"].to_sym)
if ENV["RACK_ENV"] == 'development'
  Bundler.require(:assets)
end

require 'webmate/support/sprockets'
require 'webmate/responders/exceptions'
require 'webmate/responders/base'
require 'webmate/services/base'
require 'webmate/observers/base'
require 'webmate/decorators/base'
require 'webmate/route_helpers/channels'
require 'webmate/views/helpers'

module Responders; end;
module Services; end;
module Decorators; end;
module Observers; end;

require "#{WEBMATE_ROOT}/config/config"

configatron.app.load_paths.each do |path|
  Dir[ File.join( WEBMATE_ROOT, path, '/**/*.rb') ].each do |file|
    module_name = File.dirname(file).split('/').last
    class_name = File.basename(file, '.rb')
    if configatron.app.namespaced_classes.include?(module_name)
      eval <<-EOV
        module #{module_name.camelize}
          autoload :#{class_name.camelize}, "#{file}"
        end
      EOV
    else
      eval <<-EOV
        autoload :#{class_name.camelize}, "#{file}"
      EOV
    end
  end
end

class Webmate::Application
  register Webmate::RouteHelpers::Channels
  register Sinatra::Reloader
  register SinatraMore::MarkupPlugin

  helpers Webmate::Views::Helpers
  helpers Sinatra::Cookies
  helpers Sinatra::Sprockets::Helpers

  set :_websocket_channels, {}
  set :_websocket_redis_publisher, Proc.new { @_websocket_redis_publisher ||= EM::Hiredis.connect }
  set :_websocket_redis_subscriber, Proc.new { @_websocket_redis_subscriber ||= EM::Hiredis.connect }

  set :public_path, '/public'
  set :root, WEBMATE_ROOT
  set :views, Proc.new { File.join(root, 'app', "views") }
  set :reloader, !configatron.app.cache_classes

  # auto-reloading dirs
  also_reload("#{WEBMATE_ROOT}/config/config.rb")
  also_reload("#{WEBMATE_ROOT}/config/application.rb")
  configatron.app.load_paths.each do |path|
    also_reload("#{WEBMATE_ROOT}/#{path}/**/*.rb")
  end
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
end

path = File.expand_path("#{WEBMATE_ROOT}/config/initializers/*.rb")
Dir[path].each { |initializer| require_relative(initializer) }

require "#{WEBMATE_ROOT}/config/application"