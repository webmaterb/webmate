module Webmate::Presenters
  class Base
    attr_reader :attrs

    def initialize(object, options = {})
      @object, @options = object, options.with_indifferent_access
      @attrs = {}
    end

    def namespace(name, &block)
      serializer = self.class.new(@object, @options)
      serializer.instance_exec(@object, &block)
      self.attrs[name] = serializer.attrs
    end

    def resource(name, object = nil, &block)
      raise "You should set name for resource" if name.blank?
      raise "You should specify object" if @object.nil? && object.nil?
      nested_name = name.to_s
      nested_object = object || @object.send(nested_name)
      if nested_object.blank?
        self.attrs[nested_name] = {}
      else
        self.attrs[nested_name] = nested_resource(nested_name, nested_object, @options, &block)
      end
    end

    def resources(name, objects = nil, &block)
      raise "You should specify object" if @object.nil? && objects.nil?
      objects = objects.flatten unless objects.nil?
      nested_objects = objects || @object.send(name.to_s)
      if nested_objects.blank?
        self.attrs[name.to_s] = []
      else
        self.attrs[name.to_s] = (nested_objects || []).inject([]) do |result, obj|
          resource = nested_resource(name, obj, @options, &block)
          resource.empty? ? result : (result << resource)
        end
      end
    end

    def attributes(*attrs, &block)
      if @object.blank?
        object = attrs.last
        attrs.delete(attrs.last)
        raise ArgumentError, "Object was not specified" if object.is_a?(Symbol)
      end

      target = object || @object
      Array.wrap(attrs).flatten.each do |attribute|
        self.attrs[attribute.to_s] = target.send(attribute.to_s)
      end
    end

    def attribute(attr, &block)
      self.attrs[attr.to_s] = yield
    end

    protected

    def nested_resource(name, object, options, &block)
      return nil if !object || object.blank?
      serializer = self.class.new(object, options)
      serializer.instance_exec(object, &block)
      serializer.attrs
    end

  end
end
