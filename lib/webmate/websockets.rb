module Webmate
  class Websockets
    class << self
      def subscribe(session_id, request, &block)
        user_id = request.env['warden'].try(:user).try(:id)

        request.websocket do |websocket|
          # subscribe user to redis channel
          subscribe_to_personal_channel(user_id, websocket)

          websocket.onopen do
            websocket.send(Webmate::SocketIO::Packets::Connect.new.to_packet)
            warn("Socket connection opened for session_id: #{session_id}")
          end

          websocket.onmessage do |message|
            request = Webmate::SocketIO::Packets::Base.parse(message)
            response = block.call(Webmate::SocketIO::Packets::Base.parse(message))
            if response
              packet = Webmate::SocketIO::Packets::Message.build_response_packet(response)
              websocket.send(packet.to_packet)
            else
              packet = Webmate::SocketIO::Packets::Error.build_response_packet("empty response for #{message.inspect}")
              websocket.send(packet.to_packet)
            end
          end

          websocket.onclose do
            warn("Socket connection closed '#{session_id}'")
          end
        end
      end

      def subscribe_to_personal_channel(user_id, websocket)
        channel_name = Webmate::Application.get_channel_name_for(user_id)

        subscriber = EM::Hiredis.connect.pubsub
        subscriber.subscribe(channel_name)
        warn("user has been subscribed to channel '#{channel_name}'")

        subscriber.on(:message) do |channel, message_data|
          response_data = Webmate::Application.restore(message_data)
          packet = Webmate::SocketIO::Packets::Message.new(response_data)

          websocket.send(packet.to_packet)
        end

        subscriber
      end
    end
  end
end
