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
require 'webmate/support/json'

require 'bundler'
Bundler.setup
if Webmate.env == 'development'
  Bundler.require(:assets)
end

require 'webmate/views/scope'
require 'webmate/responders/exceptions'
require 'webmate/responders/abstract'
require 'webmate/responders/base'
require 'webmate/responders/response'
require 'webmate/responders/templates'
require 'webmate/observers/base'
require 'webmate/routes/collection'
require 'webmate/routes/base'
require 'webmate/routes/handler'

Bundler.require(:default, Webmate.env.to_sym)

require 'webmate/socket.io/request'
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

require 'webmate/presenters/base'
require 'webmate/presenters/scoped'
require 'webmate/presenters/base_presenter'

# require priority initialization files
configatron.app.priotity_initialize_files.each do |path|
  file = "#{Webmate.root}/#{path}"
  require file if FileTest.exists?(file)
end

# auto-load files
configatron.app.load_paths.each do |path|
  Dir[ File.join( Webmate.root, path, '**', '*.rb') ].each do |file|
    class_name = File.basename(file, '.rb')
    eval <<-EOV
      autoload :#{class_name.camelize}, "#{file}"
    EOV
  end
end

# require initialization files
configatron.app.initialize_paths.each do |path|
  Dir[ File.join( Webmate.root, path, '**', '*.rb')].each do |file|
    require file
  end
end

class Webmate::Application
  register Sinatra::Reloader
  register SinatraMore::MarkupPlugin

  helpers Sinatra::Cookies
  helpers Webmate::Sprockets::Helpers

  set :public_path, "#{Webmate.root}/public"
  set :root, Webmate.root
  set :reloader, !configatron.app.cache_classes

  set :views, Proc.new { File.join(root, 'app', "views") }
  set :layouts, Proc.new { File.join(root, 'app', "views", "layouts") }

  if Webmate.env == 'development' # use cache classes here?
    set :template_cache, Proc.new { Tilt::Cache.new }
  else
    set :template_cache, Tilt::Cache.new
  end

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

Webmate::Sprockets.configure do |config|
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
