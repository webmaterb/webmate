module Webmate
  class Websockets
    class_attribute :channels
    class << self

      def subscribe(channel_name, request, &block)
        init_connection
        subscriber.subscribe(channel_name)
        request.websocket do |websocket|
          websocket.onopen do
            channels[channel_name] ||= []
            channels[channel_name] << websocket
            websocket.send(Webmate::SocketIO::Packets::Connect.new.to_packet)
            warn("Socket opened and added to channel '#{channel_name}'")
          end
          websocket.onmessage do |message|
            block.call(Webmate::SocketIO::Packets::Base.from_packet(message))
            warn("Socket on channel '#{channel_name}' received a message: " + message.inspect)
          end
          websocket.onclose do
            channels[channel_name].delete(websocket)
            warn("Socket closed and removed from channel '#{channel_name}'")
          end
        end
      end

      # channel_name, response
      def publish(channel_name, response)
        publisher.publish(channel_name, response).errback { |e| puts(e); raise e.inspect }
      end

      def subscriber
        @subscriber ||= EM::Hiredis.connect
      end

      def publisher
        @publisher ||= EM::Hiredis.connect
      end

      def init_connection
        return if @initialized_connection
        subscriber.on(:message){|channel, message|
          channels[channel].each{|s| s.send(message) }
        }
        self.channels ||= {}
        @initialized_connection = true
      end

#      def channel_from_path(path, action = nil)
#        # cleanup
#        channel = path.gsub(/^\//, '').gsub(/\/$/, '')
#        channel = channel.gsub(/#{action}$/, '') if action
#        channel.gsub!(/\/$/, '')
#
#        # according to socket.io,
#        # we have following path
#        # /resource_name/version/transport/session_id
#        channel_name, version, transport, session_id = channel.split('/')
#        channel_name
#      end
    end
  end
end
