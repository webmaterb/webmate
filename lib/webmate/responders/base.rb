require 'webmate/responders/abstract'
module Webmate::Responders
  class Base < Abstract
    after_filter :_run_observer_callbacks

    def _run_observer_callbacks
      async do
        Webmate::Observers::Base.execute_all(action, @response)
      end
    end
  end
end
