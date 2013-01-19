require 'webmate/responders/abstract'
module Webmate::Responders
  class Base < Abstract
    after_filter :_run_observer_callbacks
    after_filter :_send_websocket_events

    def _send_websocket_events
      Webmate::Websockets.publish(params[:channel], response.json)
    end

    def _run_observer_callbacks
      async do
        Webmate::Observers::Base.execute_all(action, response)
      end
    end
  end
end