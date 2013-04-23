module Webmate::Responders
  class RenderingScope
    include Webmate::Views::Helpers
    include Sinatra::Cookies
    include Sinatra::Sprockets::Helpers

    def initialize(responder)
      @responder = responder
    end

    def user_websocket_token
    end

    def current_user
      @responder.request.env['warden'].user('user')
    end

    def current_user_id
      @responder.request.env['warden'].user('user').id
    end
  end
end
