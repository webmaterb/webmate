# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require 'webmate/version'

Gem::Specification.new do |gem|
  gem.name          = "webmate"
  gem.version       = Webmate::VERSION

  gem.authors       = ["Iskander Haziev"]
  gem.email         = ["gvalmon@gmail.com"]
  gem.description   = %q{Real-time web application framework in Ruby}
  gem.summary       = %q{Real-time web application framework in Ruby}
  gem.homepage      = "https://github.com/webmate/webmate"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = "webmate"
  gem.require_paths = ["lib"]

  gem.add_dependency("thin")
  gem.add_dependency("em-synchrony")
  gem.add_dependency("sinatra")
  gem.add_dependency("sinatra-synchrony")
  gem.add_dependency("sinatra-contrib")
  gem.add_dependency("sinatra-websocket")
  gem.add_dependency("yajl-ruby")
  gem.add_dependency("configatron")
  gem.add_dependency("rack-contrib")
  gem.add_dependency("sinatra_more")
end
