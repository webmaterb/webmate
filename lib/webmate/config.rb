Webmate::Application.configure do |config|
  # these files will be required with high priority
  config.app.priotity_initialize_files = ["config/config.rb"]
  # files from these paths will be required on prod env and auto-loaded on dev env
  config.app.load_paths = ["app/responders", "app/models", "app/services", "app/decorators"]
  # files from these paths will be required on on any env
  config.app.initialize_paths = ["app/observers", "app/routes"]
  config.app.cache_classes = false

  config.app.name = 'webmate'
  config.app.host = 'localhost'
  config.app.port = 80
  config.app.host_with_port = Configatron::Delayed.new { "#{configatron.app.host}:#{configatron.app.port}" }

  config.logger.path = "#{Webmate.root}/log"

  config.assets.debug = false
  config.assets.compress = false
  config.assets.compile = true
  config.assets.digest = false

  config.cookies.key = Configatron::Delayed.new { "_#{configatron.app.name}_session" }
  config.cookies.domain = nil
  config.cookies.secret = "65e604cae451847ff2722ba84cb13db90f1b0a9ddc35a37169bec"

  config.websockets.enabled = true
  config.websockets.port = 80
  config.websockets.namespace = 'http_over_websocket'
end