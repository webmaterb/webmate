module Webmate::Routes
  class Handler
    attr_accessor :application, :request

    def initialize(application, request)
      @application = application
      @request = request
    end

    def handle(route_info)
      if request.websocket?
        unless websocket_connection_authorized?(request)
          return  [401, {}, []]
        end

        session_id = route_info[:params][:session_id]
        Webmate::Websockets.subscribe(session_id, request) do |request|
          if route_info = application.routes.match(request[:method], 'WS', request.path)
            request_info = prepare_response_params(route_info, request)
            response = route_info[:responder].new(request_info).respond
          end
        end

        # this response not pass to user - so we keep connection alive.
        # passing other response will close connection and socket
        [-1, {}, []]

      else # HTTP
        request_info = prepare_response_params(route_info, request)
        response = route_info[:responder].new(request_info).respond
        response.to_rack
      end
    end

    # this method prepare data for responder from request
    # @param Hash request_info = { path: '/', metadata: {}, action: 'index', params: { test: true } }
    def prepare_response_params(route_info, request)
      # create unified request info
      request_params = request_params_all(request)
      metadata = request_params.delete(:metadata)
      {
        path: request.path,
        metadata: metadata || {},
        action: route_info[:action],
        params: request_params.merge(route_info[:params]),
        request: request
      }
    end

    # Get and parse all request params
    def request_params_all(request)
      request_params = HashWithIndifferentAccess.new
      request_params.merge!(request.params || {})

      # read post or put params. this will erase  params
      # {code: 123, mode: 123}
      # "code=123&mode=123"
      request_body = request.body.read
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

    # Check that client with that scope is authorized to open connection
    def websocket_connection_authorized?(request)
      true
    end
  end
end
