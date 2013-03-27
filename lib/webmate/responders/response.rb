require 'webmate/responders/abstract'
module Webmate::Responders
  class Response
    attr_accessor :data, :status, :params, :action, :resource
    def initialize(data, options = {})
      @data = data
      @status = options[:status] || 200
      @params = options[:params] || {}
      @action = options[:action] || @params[:action] || ''
      @resource = @params[:resource]
    end

    def json
      Yajl::Encoder.new.encode(self.packed)
    end

    def packed
      { action: @action, resource: @resource, response: @data, params: safe_params }
    end

    def safe_params
      safe_params = {}
      params.each do |key, value|
        if value.is_a?(String) || value.is_a?(Integer)
          safe_params[key] = value
        end
      end
      safe_params
    end
  end
end
