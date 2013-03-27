module Webmate
  module SocketIO
    module Actions
      class Handshake
        def initialize(options = {})
          @session_id = generate_session_id

          default_options = {
            transports: %w{websocket},
            heartbeat_timeout: 300,
            closing_timeout: 300
          }
          @settings = OpenStruct.new(default_options.merge(options))
        end

        def respond
          body = [
            @session_id,
            @settings.heartbeat_timeout,
            @settings.closing_timeout,
            @settings.transports.join(',')
          ]
          [200, {}, body.join(':')]
        end

        private

        def generate_session_id
          SecureRandom.hex
        end
      end
    end
  end
end
