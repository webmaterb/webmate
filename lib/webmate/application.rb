module Webmate
  class Application < Sinatra::Base
    class << self
      def configure(env = nil, &block)
        if !env || Webmate.env?(env)
          block.call(configatron)
        end
      end
    end
  end
end