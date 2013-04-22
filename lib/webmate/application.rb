module Webmate
  class Application < Sinatra::Base
    # override sinatra's method
    def route!(base = settings, pass_block = nil) 
      transport = @request.websocket? ? 'WS' : 'HTTP'

      route_info = base.routes.match(@request.request_method, transport, @request.path)

      # no route case - use default sinatra's processors
      if !route_info
        route_eval(&pass_block) if pass_block
        route_missing
      end

      if @request.websocket?
        unless authorized_to_open_connection?(route_info[:params][:scope])
          return  [401, {}, []]
        end

        session_id = route_info[:params][:session_id].inspect
        Webmate::Websockets.subscribe(session_id, @request) do |message|
          if route_info = base.routes.match(message['method'], 'WS', message.path)
            request_info = {
              path: message.path,
              metadata: message.metadata || {},
              action: route_info[:action],
              params: message.params.merge(route_info[:params]),
              request: @request
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

        return response.rack_format
      end
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
        params: request_params.merge(route_info[:params]),
        request: @request
      }
    end

    # @request.params  working only for get params
    # and params in url line ?key=value
    def parsed_request_params
      request_params = HashWithIndifferentAccess.new
      request_params.merge!(@request.params || {})

      # read post or put params. this will erase  params
      # {code: 123, mode: 123}
      # "code=123&mode=123"
      request_body = @request.body.read
      if request_body.present?
        body_params = begin
          JSON.parse(request_body) # {code: 123, mode: 123}
        rescue JSON::ParserError
          Rack::Utils.parse_nested_query(request_body) # "code=123&mode=123"
        end
      else
        body_params = {}
      end

      request_params.merge(body_params) 
    end

    # update this method to create auth restrictions
    def authorized_to_open_connection?(scope = :user)
      return true
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

      def get_channel_name_for(user_id)
        channel_name = "some-unique-key-for-app-#{user_id}"
      end

      def dump(obj)
        Yajl::Encoder.encode(obj)
      end

      def load(str)
        Yajl::Parser.parse(str)
      end
    end
  end
end
