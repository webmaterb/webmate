module Webmate
  class Application < Sinatra::Base
    # override sinatra's method
    def route!(base = settings, pass_block = nil) 
      #raise Webmate::Application.settings.routes.inspect
      #raise 'search routes from ' + base.routes.inspect
      if routes = base.routes[@request.request_method]
        routes.each do |pattern, keys, conditions, block|
          pass_block = process_route(pattern, keys, conditions) do |*args|
            route_eval { block[*args] }
          end  
        end  
      end  

      # Run routes defined in superclass.
      if base.superclass.respond_to?(:routes)
        return route!(base.superclass, pass_block)
      end  

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
