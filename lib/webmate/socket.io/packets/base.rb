module Webmate
  module SocketIO
    module Packets
      class Base
        cattr_accessor :current_id

        attr_writer :packet_id, :packet_endpoint

        # the same order, as in socket io packet.packets
        PACKETS_TYPES = %W{
          disconnect
          connect
          heartbeat
          message
          json
          event
          ack
          error
          noop
        }
        def initialize(packet_data = {})
          @packet_data = packet_data
        end

        def self.from_packet(packet)
          packet_type_id, packet_id, packet_endpoint, packet_data = packet.split(':', 4)
          packet_type = PACKETS_TYPES[packet_type_id.to_i]
          packet_data = Yajl::Parser.new(symbolize_keys: true).parse(packet_data)

          packet_class = "Webmate::SocketIO::Packets::#{packet_type.classify}".constantize

          packet = packet_class.new(packet_data)
          packet.packet_id = packet_id
          packet.packet_endpoint = packet_endpoint

          packet
        end

        # socket io spec
        #[message type] ':' [message id ('+')] ':' [message endpoint] (':' [message data]) 
        def to_packet
          encoded_data = Yajl::Encoder.new.encode(packet_data)
          [
            packet_type_id,
            packet_id,
            packet_endpoint,
            encoded_data
          ].join(':')
        end

        def packet_id
          @id ||= generate_packet_id
        end

        def packet_type_id
          PACKETS_TYPES.index(self.packet_type)
        end

        def packet_endpoint
          @packet_endpoint ||= ''
        end

        def packet_data
          (@packet_data || {})
        end

        def generate_packet_id
          self.class.current_id ||= 0
          self.class.current_id += 1
        end
      end
    end
  end
end
