# this class emulates Sinatra::Requst class for SocketIO.
module Webmate::SocketIO
  class Request
    attr_accessor :params, :path, :method, :body

    def initialize(options = {})
      @params = options[:params]
      @path = options[:path]
      @method = options[:method]
      @body = options[:body] || ''
    end

    def body
      @body.is_a?(String) ? StringIO.new(@body) : @body
    end
  end
end