module Webmate
  class Application < Sinatra::Base
    # override sinatra's method
    def route!(base = settings, pass_block = nil) 
      transport = @request.websocket? ? 'WS' : 'HTTP'
      log_request_started(@request)

      route_info = base.routes.match(@request.request_method, transport, @request.path)

      # no route case - use default sinatra's processors
      if !route_info
        log_request_result(404, 'Not Found')
        route_eval(&pass_block) if pass_block
        route_missing
      end

      if @request.websocket?
        unless authorized_to_open_connection?(route_info[:params][:scope])
          log_request_result('401', 'Access Denied')
          return  [401, {}, []]
        end

        session_id = route_info[:params][:session_id].inspect
        Webmate::Websockets.subscribe(session_id, @request) do |message|
          log_request_started(@request, message)
          if route_info = base.routes.match(message['method'], 'WS', message.path)
            request_info = {
              path: message.path,
              metadata: message.metadata || {},
              action: route_info[:action],
              params: message.params.merge(route_info[:params]),
              request: @request
            }
            log_route_info(route_info, request_info[:params])
            # here we should create subscriber who can live
            # between messages.. but not between requests.
            response = route_info[:responder].new(request_info).respond

            log_request_result(response.status)

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
        log_route_info(route_info, parsed_request_params)
        response = route_info[:responder].new(request_info).respond

        log_request_result(response.status)
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

    private

    def log(text, level = :debug)
      Webmate.logger.dump(text)
    end

    def log_request_started(request, message = nil)
      if message
        log("Started #{message['method']} [WS] #{message.path} for #{request.ip} at #{Time.now.to_s}")
      else
        transport = request.websocket? ? 'WS' : 'HTTP'
        log("Started #{request.request_method} [#{transport}] #{request.path} for #{request.ip} at #{Time.now.to_s}")
      end
    end

    def log_route_info(route_info, params)
      log("Processing #{route_info[:responder].to_s}##{route_info[:action]} with params: #{params}")
    end

    def log_request_result(status, description = nil)
      description = 'OK' if status.to_i == 200
      log("Completed #{status.to_s} #{description}")
      Webmate.logger.flush
    end

    public

    class << self
      def configure(env = nil, &block)
        if !env || Webmate.env?(env)
          block.call(configatron)
        end
      end

      def define_routes(&block)
        settings = Webmate::Application
        unless settings.routes.is_a?(RoutesCollection)
          routes = RoutesCollection.new(configatron.websockets.to_hash)
          settings.set(:routes, routes)
        end
        settings.routes.define_routes(&block)

        routes
      end

      def get_channel_name_for(user_id)
        channel_name = "some-unique-key-for-app-#{user_id}"
      end

      def dump(obj)
        Yajl::Encoder.encode(obj)
      end

      def restore(str)
        Yajl::Parser.parse(str)
      end

      def load_tasks
        file_path = Pathname.new(__FILE__)
        load File.join(file_path.dirname, "../../tasks/routes.rake")
      end
    end
  end
end
