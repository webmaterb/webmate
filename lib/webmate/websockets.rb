module Webmate
  class Websockets
    class_attribute :channels
    class << self

      def subscribe(request, &block)
        channel = request.path.gsub(/^\//, '')
        init_connection
        subscriber.subscribe(channel)
        request.websocket do |ws|
          ws.onopen do
            channels[channel] ||= []
            channels[channel] << ws
          end
          ws.onmessage do |msg|
            request.params.merge! Yajl::Parser.new(symbolize_keys: true).parse(msg)
            block.call(request)
          end
          ws.onclose do
            warn("websocket closed")
            channels[channel].delete(ws)
          end
        end
      end

      def publish(action, body)
        publisher.publish(action, body).errback { |e| puts(e) }
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
    end
  end
end