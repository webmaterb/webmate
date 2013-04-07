require 'webmate/responders/callbacks'
module Webmate::Responders
  class Abstract
    attr_accessor :action, :path, :metadata, :params

    def initialize(request_info)
      @action = request_info[:action]
      @path   = request_info[:path]
      @metadata = request_info[:metadata]
      @params  = request_info[:params]

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
        default_options = {status: 200, params: params}
        options = default_options.merge(options)
        @response = Response.new(response, options)
      end
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
  end
end
=begin
  class Abstract
    attr_accessor :action, :params, :request, :response

    def initialize(request)
      @request = request
      @params = request.params
      @action = params[:action]
      @response = nil
    end

    def action_method
      action.to_s.split('/').last
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
        default_options = {status: 200, params: params}
        options = default_options.merge(options)
        @response = Response.new(response, options)
      end
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
  end
=end
