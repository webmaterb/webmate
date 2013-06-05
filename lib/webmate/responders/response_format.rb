module Webmate::Responders
  module ResponseFormat
    extend ActiveSupport::Concern

    def convert_to_request_format(responder_result)
      return responder_result if responder_result.is_a?(String)

      settings = self.class.format_settings
      format = params[:format].to_s
      if format.blank? || !settings[:formats].include?(format.to_sym)
        format = settings[:default].to_s
      end

      to_format = "to_#{format}"
      if responder_result.respond_to?(to_format)
        return responder_result.send(to_format)
      else
        return responder_result
      end
    end

    module ClassMethods
      # respond_to :json, :html, :xml, default: :json
      def respond_to(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        formats = args.length > 0 ? args.map{|x| x.downcase.to_sym } : [:html, :json]
        default_format = options.symbolize_keys[:default] || formats.first || :json
        @format_settings = { formats: formats, default: default_format }
      end

      def get_format_settings
        @format_settings
      end

      # should return 
      # { formats: [...], default: :json }
      def format_settings
        #puts self.class.ancestors.inspect
        return @format_settings if @format_settings

        self.ancestors.each do |base|
          @format_settings ||= begin
            base.respond_to?(:get_format_settings) ? base.get_format_settings : nil
          end
        end

        @format_settings ||= {}
      end
    end
  end
end
