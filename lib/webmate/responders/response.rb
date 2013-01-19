require 'webmate/responders/abstract'
module Webmate::Responders
  class Response
    attr_accessor :data, :status, :params, :action
    def initialize(data, options = {})
      @data = data
      @status = options[:status] || 200
      @params = options[:params] || {}
      @action = @params[:action] || ''
    end

    def json
      Yajl::Encoder.new.encode(
        action: action, response: data, params: params
      )
    end
  end
end