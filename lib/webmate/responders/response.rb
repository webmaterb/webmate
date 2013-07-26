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
  end
end
