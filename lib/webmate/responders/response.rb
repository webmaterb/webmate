require 'webmate/responders/abstract'
module Webmate::Responders
  class Response
    attr_accessor :data, :status, :params, :action, :path, :metadata
    def initialize(data, options = {})
      @data = data
      @status = options[:status] || 200
      @params = options[:params] || {}
      @action = options[:action] || @params[:action] || ''
      @metadata = options[:metadata] || {}
      @path = options[:path] || "/"
    end

    def to_rack
      [@status, {}, @data]
    end

    def to_packet
      Webmate::SocketIO::Packets::Message.build_response_packet(self).to_packet
    end

    class << self
      def build_not_found(message, options = {})
        self.new(message, {status: 404}.merge(options))
      end

      def build_error(message, options = {})
        self.new(message, {status: 500}.merge(options))
      end
    end
  end
end
