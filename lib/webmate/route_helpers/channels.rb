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

          websocket_publisher = settings._websocket_redis_publisher
          websocket_subscriber = settings._websocket_redis_subscriber
          websocket_subscriber.subscribe(request.path)
          websocket_subscriber.on(:message){|channel, message|
            settings._websocket_channels[channel].each{|s| s.send(message) }
          }
          request.websocket do |ws|
            ws.onopen do
              settings._websocket_channels[request.path] ||= []
              settings._websocket_channels[request.path] << ws
            end
            ws.onmessage do |msg|
              request.params.merge! Yajl::Parser.new(symbolize_keys: true).parse(msg)
              response = RouterChannel.respond_to(path, request)
              if response.first == 200
                websocket_publisher.publish(request.path, response.last).errback { |e|
                  puts(e)
                }
              end
              puts "WebSocket #{path} #{request.params[:action]} #{response.first}"
              puts "Params: #{request.params.inspect}"
              puts ""
            end
            ws.onclose do
              warn("websocket closed")
              settings._websocket_channels[request.path].delete(ws)
            end
          end
        end
        channel.routes.each do |route|
          responder_block = lambda do
            request.params.merge!(action: route[:action])
            response = route[:responder].new(request).respond
            status, body = *response
            status == 200 ? body : [status, {}, body]
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