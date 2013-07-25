module Webmate::Routes
  class Handler
    attr_accessor :application, :request

    def initalize(application, request)
      @application = application
      @request = request
    end

    def handle(route_info)
      responder = route_info.delete(:responder)
      if request.websocket?
        unless websocket_connection_authorized?(request)
          return  [401, {}, []]
        end

        session_id = route_info[:params][:session_id]
        Webmate::Websockets.subscribe(session_id, request) do |message|
          if route_info = application.routes.match(message['method'], 'WS', message.path)
            request_info = params_from_websoket(route_info, message)
            # here we should create subscriber who can live
            # between messages.. but not between requests.
            responder.new(request_info).respond
          end
        end

        # this response not pass to user - so we keep connection alive.
        # passing other response will close connection and socket
        [-1, {}, []]

      else # HTTP
        # this should return correct Rack response..
        request_info = params_from_http(route_info)
        response = responder.new(request_info).respond
        response.rack_format
      end
    end

    # this method prepare data for responder from http request
    # @param Hash request_info = { path: '/', metadata: {}, action: 'index', params: { test: true } }
    def params_from_http(route_info)
      # create unified request info
      request_params = parsed_request_params
      metadata = request_params.delete(:metadata)
      {
        path: request.path,
        metadata: metadata || {},
        action: route_info[:action],
        params: request_params.merge(route_info[:params]),
        request: request
      }
    end

    # this method prepare data for responder from http request
    def params_from_websoket(route_info, message)
      {
        path: message.path,
        metadata: message.metadata || {},
        action: route_info[:action],
        params: message.params.merge(route_info[:params])
      }
    end

    # Get and parse all request params
    def http_body_request_params
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

    # Check that client with that scope is authorized to open connection
    def websocket_connection_authorized?(request)
      true
    end
  end
end
