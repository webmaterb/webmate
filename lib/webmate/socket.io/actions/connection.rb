module Webmate
  module SocketIO
    module Actions
      class Connection
        def initialize(request)
          @request = request
        end

        def respond(base)
          channel_name = "channel-#{Time.now.to_i}"
          Webmate::Websockets.subscribe(channel_name, @request) do |message|
            if route_info = app.routes.match(message.method, 'WS', message.path)
              route_info[:responder].new.respond
            end
          end
        end
      end
    end
  end
end
