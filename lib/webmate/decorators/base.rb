module Webmate::Decorators
  class Base
    attr_reader :entity, :options

    def initialize(entity, options = {})
      @entity, @options = entity, options
    end

    class << self
      def decorate(entity_or_collection, options = {})
        if entity_or_collection.respond_to?(:map)
          entity_or_collection.map { |e| self.decorate(e, options) }
        else
          self.new(entity_or_collection, options)
        end
      end
    end

    def id
      entity.id.to_s
    end

    def method_missing(method, *args, &block)
      if entity.respond_to?(method)
        self.class.send :define_method, method do |*args, &blokk|
          entity.send method, *args, &blokk
        end

        send method, *args, &block
      else
        super
      end
    rescue NoMethodError => no_method_error
      super if no_method_error.name == method
      raise no_method_error
    end
  end
end