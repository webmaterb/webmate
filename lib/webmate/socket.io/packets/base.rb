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
          @packet_data  = packet_data.with_indifferent_access
        end

        # packet should be created by socket.io spec 
        #[message type] ':' [message id ('+')] ':' [message endpoint] (':' [message data]) 
        # and webmate spec
        # message_data = {
        #   method: GET/POST/...
        #   path: '/projects'
        #   params: {}
        #   metadata: { data should be returned back with answer }
        # }
        def self.parse(packet)
          # last element is encoded json array, so there can be many ':'
          packet_type_id, packet_id, packet_endpoint, json_data = packet.split(':', 4)

          packet_data = (Yajl::Parser.parse(json_data) || {}).with_indifferent_access

          if packet_data[:params].is_a?(String)
            packet_data[:params] = Yajl::Parser.parse(packet_data[:params])
          end

          if packet_data[:metadata].is_a?(String)
            packet_data[:metadata] = Yajl::Parser.parse(packet_data[:metadata])
          end

          packet = OpenStruct.new(
            path: packet_data[:path],
            method: packet_data[:method],
            params: packet_data[:params] || {},
            metadata: packet_data[:metadata] || {},
            packet_id: packet_id,
            packet_endpoint: packet_endpoint
          )

          packet
        end

        # convert response from Responders::Base to socket io message
        # 
        def self.build_response_packet(response)
          new(self.prepare_packet_data(response))
        end

        def self.prepare_packet_data(response)
          packet_data = {
            action:   response.action,
            body:     response.data,
            path:     response.path,
            params:   response.params,
            metadata: response.metadata,
            status:   response.status
          }
        end

        # socket io spec
        #[message type] ':' [message id ('+')] ':' [message endpoint] (':' [message data]) 
        def to_packet
          data = {
            action: action,
            request: { 
              path:     path, 
              metadata: metadata
            },
            response: {
              body: body,
              status: status || 200
            }
          }
          encoded_data = Yajl::Encoder.new.encode(data)
          [
            packet_type_id,
            packet_id,
            packet_endpoint,
            encoded_data
          ].join(':')
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

        def metadata
          packet_data[:metadata]
        end

        def path
          packet_data[:path]
        end

        def action
          packet_data[:action]
        end

        def params
          packet_data[:params]
        end

        def body
          packet_data[:body]
        end

        def status
          packet_data[:status]
        end

        def packet_id
          @id ||= generate_packet_id
        end

        # update counter
        def packet_id=(new_packet_id)
          self.class.current_id = new_packet_id
          @id ||= generate_packet_id
        end

        # unique packet id
        # didn't find any influence for now, 
        # uniqueness not matter
        def generate_packet_id
          self.class.current_id ||= 0
          self.class.current_id += 1
        end
      end
    end
  end
end
