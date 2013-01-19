require 'yajl'
require 'em-hiredis'
module Webmate
  module RouteHelpers
    module Channels
      def channel(path, &block)
        channel = RouterChannel.new(path)
        channel.define_actions(&block)
        get "/#{path}" do
          pass unless request.websocket?

          Webmate::Websockets.subscribe(request) do |request|
            response = RouterChannel.respond_to(path, request)
            params = request.params
            puts "WebSocket #{params[:channel]} #{params[:action]} #{response.status}"
            puts "Params: #{params.inspect}"
            puts ""
          end
        end
        channel.routes.each do |route|
          responder_block = lambda do
            channel = request.path.gsub(/#{route[:action]}$/, '').gsub(/^\//, '')
            request.params.merge!(action: route[:action], channel: channel)
            response = route[:responder].new(request).respond
            response.status == 200 ? response.body : [response.status, {}, response.body]
          end
          send(route[:method], route[:route], {}, &responder_block)
        end
        channel.routes
      end

      class RouterChannel
        attr_accessor :routes
        attr_accessor :path

        class << self
          attr_accessor :channels

          def add_channel_action(path, action, options)
            self.channels ||= {}
            self.channels[path] ||= {}
            self.channels[path][action] = options
          end

          def respond_to(path, request)
            params = request.params
            if channels[path] && channels[path][params[:action]]
              channels[path][params[:action]][:responder].new(request).respond
            else
              Webmate::Responders::Base.new(request).render_not_found
            end
          end
        end

        def initialize(path)
          @path = path
          @routes = []
        end

        def define_actions(&block)
          instance_eval(&block)
        end

        [:get, :post, :delete, :patch, :put].each do |method|
          define_method method.to_sym do |route|
            action, responder = route.to_a.first
            options = {
              action: action, responder: responder,
              method: method, route: "/#{path}/#{action}"
            }
            self.class.add_channel_action(path, action, options)
            self.routes << options
          end
        end
      end
    end
  end
end