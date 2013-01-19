module Webmate
  module Views
    module Helpers
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

      def javascript_include_tag(name)
        %Q{<script type="text/javascript" src="#{asset_path(name)}" ></script>}
      end

      def stylesheet_link_tag(name)
        %Q{<link rel="stylesheet" type="text/css" href="#{asset_path(name)}" />}
      end
    end
  end
end