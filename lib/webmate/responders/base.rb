require 'webmate/responders/callbacks'
module Webmate::Responders
  class Base
    attr_accessor :action, :params, :request

    def initialize(request)
      @request = request
      @params = request.params
      @action = params[:action]
    end

    def action_method
      action.split('/').last
    end

    def respond
      process_action
    rescue Exception => e
      rescue_with_handler(e)
    end

    def rescue_with_handler(exception)
      if handler = handler_for_rescue(exception)
        handler.arity != 0 ? handler.call(exception) : handler.call
      else
        raise(e)
      end
    end

    def process_action
      raise Webmate::Responders::ActionNotFound unless respond_to?(action_method)
      response = self.send(action_method)
      async do
        Webmate::Observers::Base.execute_all(
          action, {action: action, response: response, params: params}
        )
      end
      [200, wrap_response(response)]
    end

    def wrap_response(response)
      Yajl::Encoder.new.encode(
        action: action, response: response, client_id: params[:client_id]
      )
    end

    def render_not_found
      [404, wrap_response(response: "Action not Found")]
    end

    def async(&block)
      block.call
    end

    include ActiveSupport::Rescuable
    include Webmate::Responders::Callbacks
  end
end