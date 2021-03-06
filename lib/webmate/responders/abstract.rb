require 'em-hiredis'
require 'webmate/responders/callbacks'

module Webmate::Responders
  class Abstract
    attr_accessor :action, :path, :metadata, :params
    attr_reader :request

    # request info - current request params
    def initialize(request_info)
      @action   = request_info[:action]
      @path     = request_info[:path]
      @metadata = request_info[:metadata]
      @params   = request_info[:params]
      @request  = request_info[:request]

      # publishing actions
      @users_to_notify = []

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
      # publish changes to users actions
      async { publish(@response) }

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
    def publisher
      @publisher ||= build_connection
    end

    def build_connection
      EM::Hiredis.connect
    rescue
      warn("problem with connections to redis")
      nil
    end

    # publish current response to private channels
    # for users in user_ids
    #
    # publish_to(123, 456)
    def publish_to(*user_ids)
      @users_to_notify += user_ids
    end

    # take @users_to_notify
    # and pass back channels names with listeners
    #
    def channels_to_publish
      @users_to_notify.flatten.each_with_object([]) do |user_id, channels|
        channel_name = Webmate::Application.get_channel_name_for(user_id)
        channels << channel_name if channel_active?(channel_name)
      end
    end

    def channel_active?(channel_name)
      return true # in development
    end

    def publish(response)
      return if publisher.nil?

      # prepare args for socket.io message packet
      # this should be prepared data to create socket.io message
      # without any additional actions
      packet_data = Webmate::SocketIO::Packets::Message.prepare_packet_data(response)
      data = Webmate::JSON.dump(packet_data)

      channels_to_publish.each {|channel_name| publisher.publish(channel_name, data) }
    end
  end
end
