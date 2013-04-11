require 'webmate/responders/callbacks'
module Webmate::Responders
  class Abstract
    attr_accessor :action, :path, :metadata, :params

    # request info - current request params
    #
    # event_bus - redis connection, 
    #   which persists between requests
    #   and should be single for each websocket transport connection
    #   but can be short-lived for http request [ create - fire - forgot ]
    def initialize(request_info, event_bus = nil)
      @action = request_info[:action]
      @path   = request_info[:path]
      @metadata = request_info[:metadata]
      @params  = request_info[:params]

      # redis client
      @event_bus = event_bus
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

    # subscribe_to "project/#{project.id}/tasks"
    def subscribe_to(channel_name)
      return unless event_bus.present?
      event_bus.subscribe(channel_name)
    end

    # publish_to("project/#{project.id}/tasks", "create", response, to: [],
    def publish_to(channel_name, options)
      @publish_queue << [channel_name, options]
    end

    def publish(response)
      connection = build_connection
      @publish_queue.each do |channel_name, options|
        # this should be prepared data to create socket.io message without
        # any additional checks
        data = {
          response: Webmate::SocketIO::Packets::Message.prepare_packet_data(response),
          options: options
        }
        connection.publish(channel_name, YAML::dump(data))
      end
    end
  end
end
