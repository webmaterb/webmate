module Webmate::Presenters
  module Scoped
    extend ActiveSupport::Concern

    def build_serialized(*args, &block)
      object = args.first
      if object.is_a?(Array)
        object.map do |obj|
          get_serializable_attributes(obj, &block)
        end
      else
        get_serializable_attributes(object, &block)
      end
    end

    private

    def get_serializable_attributes(object, &block)
      serializer = serializable_class.new(object)
      instance_exec do
        serializer.instance_exec(object, &block)
      end
      serializer.attrs
    end

    def serializable_class
      Webmate::Presenters::Base
    end
  end
end
