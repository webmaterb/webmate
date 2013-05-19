module Webmate::Views
  class Scope
    include Sinatra::Cookies
    include Webmate::Sprockets::Helpers

    def initialize(responder)
      @responder = responder
    end

    def user_websocket_token
    end

    def javascript_client_configs
      %Q{<script type="text/javascript">
        if (!window.Webmate) {window.Webmate = {}};
        window.Webmate.websocketsPort = #{configatron.websockets.port};
        window.Webmate.websocketsEnabled = #{configatron.websockets.enabled ? 'true' : 'false'};
      </script>}
    end

    def user_websocket_token_tag
      %Q{<meta content="#{user_websocket_token}" name="websocket-token" />}
    end

    def request
      @responder.request
    end

    def requirejs_include_tag(file_name)
      application_file_url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/assets/#{file_name}"
      javascript_include_tag 'webmate/libs/require.js', 'data-main' => application_file_url
    end
  end
end
