module Webmate
  class Application < Sinatra::Base
    # override sinatra's method
    def route!(base = settings, pass_block = nil) 
      transport = @request.websocket? ? 'WS' : 'HTTP'

      if route_info = base.routes.match(@request.request_method, transport, @request.path)
        if @request.websocket?
          channel_name = "user-channel-#{Time.now.to_i}"
          Webmate::Websockets.subscribe(channel_name, @request) do |message|
            if route_info = base.routes.match(message.method, 'WS', message.path)
              request_info = {
                path: message.path,
                metadata: message.metadata || {},
                action: route_info[:action],
                params: message.params.merge(route_info[:params])
              }
              route_info[:responder].new(request_info).respond
            end
          end

          # this response not pass to user - so we keep connection alive.
          # passing other response will close connection and socket
          non_pass_response = [-1, {}, []]
          return non_pass_response

        else # HTTP
          # this should return correct Rack response..
          request_info = params_for_responder(route_info)
          response = route_info[:responder].new(request_info).respond

          return response
        end
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

    # this method prepare data for responder
    # {
    #   path: '/', 
    #   metadata: {}, 
    #   action: 'index', 
    #   params: { test: true } 
    # }
    def params_for_responder(route_info)
      # create unified request info 
      # request_info = { path: '/', metadata: {}, action: 'index', params: { test: true } }
      request_params = @request.params.dup
      metadata = request_params.delete(:metadata)
      {
        path: @request.path,
        metadata: metadata || {},
        action: route_info[:action],
        params: request_params.merge(route_info[:params])
      }
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
