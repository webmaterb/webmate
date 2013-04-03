module Webmate
  class Application < Sinatra::Base
    # override sinatra's method
    def route!(base = settings, pass_block = nil) 
      routes = base.routes.get_routes(@request.request_method, @request.websocket? ? 'WS' : 'HTTP')
      routes.each do |route|
        if route_info = route.match(@request.path)
          return route_info.inspect
        end
        # request pathhk
      end

      # code below remains from sinatra
      # in our case, this class and superclass 
      # has different routes type [RoutesCollection and Hash]
      #if base.superclass.respond_to?(:routes)
      #  return route!(base.superclass, pass_block)
      #end  

      route_eval(&pass_block) if pass_block
      route_missing
    end

    class << self
      def configure(env = nil, &block)
        if !env || Webmate.env?(env)
          block.call(configatron)
        end
      end

      def define_routes(&block)
        unless self.settings.routes.is_a?(RoutesCollection)
          routes = RoutesCollection.new()
          self.settings.set(:routes, routes)
        end
        self.settings.routes.define_routes(&block)

        routes
      end
    end
  end
end
