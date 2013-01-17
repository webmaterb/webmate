module Webmate
  module Views
    module Helpers
      def client_configs
        %Q{<script type="text/javascript">
          if (!window.Webmate) {window.Webmate = {}};
          window.Webmate.websocketsPort = #{configatron.websockets.port};
          window.Webmate.websocketsEnabled = #{configatron.websockets.enabled ? 'true' : 'false'};
        </script>}
      end
    end
  end
end