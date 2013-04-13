require 'webmate/responders/callbacks'
module Webmate::Responders
  class Abstract
    attr_accessor :action, :path, :metadata, :params

    # request info - current request params
    def initialize(request_info)
      @action = request_info[:action]
      @path   = request_info[:path]
      @metadata = request_info[:metadata]
      @params  = request_info[:params]

      # publishing actions
      @publish_queue = []

      @response = nil
    end

    def action_method
      action.to_s
    end

    def params
      @params.with_indifferent_access
    end

    def respond
      process_action
    rescue Exception => e
      rescue_with_handler(e)
    end

    def respond_with(response, options = {})
      if @response.is_a?(Response)
        @response = response
      else
        default_options = {
          status: 200,
          path: path,
          metadata: metadata,
          params: params,
          action: action
        }
        options = default_options.merge(options)
        @response = Response.new(response, options)
      end
      # publishing actions
      publish(@response)
      @response
    end

    def rescue_with_handler(exception)
      if handler = handler_for_rescue(exception)
        handler.arity != 0 ? handler.call(exception) : handler.call
      else
        raise(exception)
      end
    end

    def process_action
      raise ActionNotFound unless respond_to?(action_method)
      respond_with send(action_method)
    end

    def render_not_found
      @response = Response.new("Action not Found", status: 200)
    end

    def async(&block)
      block.call
    end

    include ActiveSupport::Rescuable
    include Webmate::Responders::Callbacks

    # subscriptions
    def event_bus
      @event_bus || build_connection
    end

    def build_connection
      EM::Hiredis.connect
    rescue RuntimeError => e
      #RuntimeError: eventmachine not initialized: evma_connect_to_server
      puts("WARNING! syncronius redis connection not implmented yet")
      "mock for non EM redis connectiion"
    end

    # publish current response to private channels
    # for users in user_ids
    #
    # publish_to(123, 456)
    def publish_to(*user_ids)
      @publish_queue += user_ids
    end

    def publish(response)
      connection = build_connection
      # prepare args for socket.io message packet
      # this should be prepared data to create socket.io message
      # without any additional actions
      packet = Webmate::SocketIO::Packets::Message.prepare_packet_data(response)
      data = YAML::dump(packet)
      @publish_queue.each do |user_id|
        channel_name = Webmate::Application.get_channel_name_for(user_id)
        connection.publish(channel_name, data)
      end
    end
  end
end
