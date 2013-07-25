module Webmate
  class Application < Sinatra::Base
    # override sinatra's method
    def route!(base = settings, pass_block = nil)
      route_info = find_route(base.routes, @request)

      # no route case - use default sinatra's processors
      if route_info
        handler = Webmate::Routes::Handler.new(base, @request)
        handler.handle(route_info)
      else
        route_eval(&pass_block) if pass_block
        route_missing
      end
    end

    # Find matched route by routes collection and request
    # @param Webmate::Routes::Collection routes
    # @param Sinatra::Request request
    def find_route(routes, request)
      transport = request.websocket? ? 'WS' : 'HTTP'
      routes.match(request.request_method, transport, request.path)
    end

    class << self
      def configure(env = nil, &block)
        if !env || Webmate.env?(env)
          block.call(configatron)
        end
      end

      def define_routes(&block)
        settings = Webmate::Application
        unless settings.routes.is_a?(Routes::Collection)
          routes = Routes::Collection.new()
          settings.set(:routes, routes)
        end
        settings.routes.define(&block)

        routes
      end

      def get_channel_name_for(user_id)
        channel_name = "some-unique-key-for-app-#{user_id}"
      end

      def load_tasks
        file_path = Pathname.new(__FILE__)
        load File.join(file_path.dirname, "../../tasks/routes.rake")
      end
    end
  end
end
