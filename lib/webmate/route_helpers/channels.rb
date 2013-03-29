require 'yajl'
require 'em-hiredis'

module Webmate
  module RouteHelpers
    module Channels
      def channel(channel_name, options = {}, &block)
        # use options to specify socket opening behaviour.
        channel = RouterChannel.new(channel_name)
        channel.define_routes(&block)
        
        # handshake
        get "/#{channel_name}/1/?\?:query?" do
          Webmate.logger.dump("WebSocket Handshake request: #{params.inspect}")
          response = Webmate::SocketIO::Actions::Handshake.new({}).respond
          response
        end

        get "/#{channel_name}/:protocol_version/:transport/:session_id?disconnect" do
          # forced connection closing
        end

        get "/#{channel_name}/:protocol_version/:transport/:session_id/?\?:query?" do
          pass if !request.websocket?

          # subscribe to response on message
          Webmate::Websockets.subscribe(channel_name, request) do |message|
            # TODO test memory consume with smt like RouterChannel.channels[channel_name]?
            response = channel.respond_to(message, request)
=begin
            warn("responded with: #{response.json}")
            packet = Webmate::SocketIO::Packets::Message.new(response).to_packet

            # broadcast message to all clients?
            Webmate::Websockets.channels[channel_name].each do |socket|
              socket.send(packet)
            end
=end
          end
        end
      end

      class RouterChannel
        #cattr_accessor :channels

        attr_accessor :routes
        attr_accessor :channel_name

        def initialize(channel_name)
          #self.class.channels ||= {}
          #self.class.channels[channel_name] ||= {}
          @channel_name = channel_name
          @routes = {}
        end

        def define_routes(&block)
          instance_eval(&block)
        end

        # define resource messages
        def resources(name, options = {})
          all_available_actions = %w{read update delete create get}
          options[:actions] = options[:only].present? ? options[:only].map(&:to_s) : all_available_actions
          options[:responder] ||= "#{name.to_s}Responder".classify.constantize

          @routes[name.to_s] = options
        end

        def respond_to(packet, request)
          resource = @routes[packet.packet_data[:resource]] 
          if resource && resource[:actions].include?(packet.packet_data[:action])
            #resource[:responder].new(request).send(packet.packet_data[:action]) 
            # crutch
            request.params.merge!(packet.packet_data)
            request.params[:channel] = @channel_name

            resource[:responder].new(request).respond
          else
            Webmate::Responders::Base.new(request).render_not_found
          end
        end
      end
    end
  end
end
=begin
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
            Webmate.logger.dump(
              "WebSocket: #{params[:channel]}/#{params[:action]} #{response.status} \nParams: #{params.inspect}"
            )
          end
        end
        channel.routes.each do |route|
          responder_block = lambda do
            channel_path = Webmate::Websockets.channel_from_path(request.path, route[:action])
            request.params.merge!(action: route[:action], channel: channel_path)
            response = route[:responder].new(request).respond
            response.status == 200 ? response.json : [response.status, {}, response.json]
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
=end
