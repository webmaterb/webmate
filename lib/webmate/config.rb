Webmate::Application.configure do |config|
  config.app.load_paths = ["app/responders", "app/models", "app/services", "app/observers", "app/decorators"]
  config.app.namespaced_classes = ["responders", "services", "observers", "decorators"]
  config.app.cache_classes = false

  config.assets.debug = false
  config.assets.compress = false

  config.hello.world = "Hello World"
end