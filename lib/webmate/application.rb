module Webmate
  class Application < Sinatra::Base
    # override sinatra's method
    def route!(base = settings, pass_block = nil) 
      transport = @request.websocket? ? 'WS' : 'HTTP'

      if route_info = base.routes.match(@request.request_method, transport, @request.path)
        if @request.websocket?
          channel_name = "user-channel-#{Time.now.to_i}"
          session_id = route_info[:params][:session_id].inspect
          Webmate::Websockets.subscribe(session_id, @request) do |message|
            if route_info = base.routes.match(message['method'], 'WS', message.path)
              request_info = {
                path: message.path,
                metadata: message.metadata || {},
                action: route_info[:action],
                params: message.params.merge(route_info[:params])
              }

              # here we should create subscriber who can live
              # between messages.. but not between requests.
              response = route_info[:responder].new(request_info).respond

              # result of block will be sent back to user
              response
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

          return [response.status, {}, response.data]
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
      request_params = parsed_request_params
      metadata = request_params.delete(:metadata)
      {
        path: @request.path,
        metadata: metadata || {},
        action: route_info[:action],
        params: request_params.merge(route_info[:params])
      }
    end

    # @request.params  working only for get params
    # and params in url line ?key=value
    # but this not work for post/put body params
    # issue related to parse
    def parsed_request_params
      request_params = HashWithIndifferentAccess.new
      request_params.merge!(@request.params || {})
      request_params.merge!(Rack::Utils.parse_nested_query(@request.body.read) || {})

      request_params
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
