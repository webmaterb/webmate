module Webmate
  class Websockets
    class << self

      def subscribe(session_id, request, &block)
        #init_connection
        #subscriber.subscribe(channel_name)
        request.websocket do |websocket|
          websocket.onopen do
            websocket.send(Webmate::SocketIO::Packets::Connect.new.to_packet)
            warn("Socket connection opened for session_id: #{session_id}")
          end
          websocket.onmessage do |message|
            response = block.call(Webmate::SocketIO::Packets::Base.parse(message))
            #warn("socket for '#{session_id}' \n received: #{message.inspect} and \n sent back a '#{response.inspect}")

            packet = Webmate::SocketIO::Packets::Message.build_response_packet(response)
            websocket.send(packet.to_packet)
          end
          websocket.onclose do
            #channels[channel_name].delete(websocket)
            warn("Socket connection closed '#{session_id}'")
          end
        end
      end
=begin
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
        subscriber.on(:message) do |channel, message|
          puts "channel: '#{channel}' received message: #{message.inspect}"
        end
      end
=end

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
