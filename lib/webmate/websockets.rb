module Webmate
  class Websockets
    class << self
      def subscribe(session_id, request, &block)

        request.websocket do |websocket|
          redis_event_bus = init_subscriber(websocket, session_id)

          websocket.onopen do
            websocket.send(Webmate::SocketIO::Packets::Connect.new.to_packet)
            warn("Socket connection opened for session_id: #{session_id}")
          end

          websocket.onmessage do |message|
            response = block.call(Webmate::SocketIO::Packets::Base.parse(message), redis_event_bus)
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

      # websocket - used for sending messages
      # user_credentials - used for identify current user rights
      def init_subscriber(websocket, user_credentials)
        subscriber = EM::Hiredis.connect
        subscriber.subscribe('channel')
        subscriber.on(:message) do |channel, message_data|
          parsed_message = YAML::load(message_data)
          puts "message received on channel '#{channel}': #{parsed_message}"
          response_data = parsed_message[:response]
          options       = parsed_message[:options]

          user_id = 123456 # use user_credentials for this
          receivers = options[:for] || []
          access_allowed = receivers == :all || receivers.include?(user_id)

          if access_allowed
            packet = Webmate::SocketIO::Packets::Message.new(response_data)
            websocket.send(packet.to_packet)
          end
        end

        subscriber
      end
    end
  end
end
