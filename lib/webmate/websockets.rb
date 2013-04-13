module Webmate
  class Websockets
    class << self
      def subscribe(session_id, request, &block)
        user_id = 1 # get user from session id ?

        request.websocket do |websocket|
          # subscribe user to redis channel
          subscribe_to_personal_channel(user_id, websocket)

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

      def subscribe_to_personal_channel(user_id, websocket)
        channel_name = Webmate::Application.get_channel_name_for(user_id)
        subscriber = EM::Hiredis.connect
        subscriber.subscribe(channel_name)
        warn("user has been subscribed to channel '#{channel_name}'")

        subscriber.on(:message) do |channel, message_data|
          response_data = Webmate::Application.load(message_data)
          packet = Webmate::SocketIO::Packets::Message.new(response_data)

          websocket.send(packet.to_packet)
        end

        subscriber
      end
    end
  end
end
