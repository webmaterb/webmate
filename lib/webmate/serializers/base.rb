# usage example
#
# class ProjectSerializer
#   attributes :id, :name
#   attributes :description, profile: detailed
#   attributes :example
#
#   def example
#
#   end
#
#   # not implemented
#   has_many: tasks,
#     serializer: TasksSerializer,
#     profile: default
#
#
# end
# 
# profiles: default, extended, short
#
# responder
#   ProjectSerializer(@projects).to_json(profile: detailed)
module Webmate
  module Serializers
    class Base
      class_attribute :_attributes
      attr_reader :entity_or_collection

      def initialize(entity_or_collection)
        @entity_or_collection = entity_or_collection || []
        @entity_or_collection.delete_if(&:blank?) if @entity_or_collection.is_a?(Array)
      end

      # switch to default method, possible
      # like to_s
      #
      def to_json(profile = :default)
        if @entity_or_collection.is_a?(Array)
          json_data = @entity_or_collection.map do |object|
            get_attributes_for(object, profile)
          end
        else # single object
          json_data = get_attributes_for(@entity_or_collection, profile)
        end
        Yajl::Encoder.encode(json_data)
      end

      private

      def get_attributes_for(object, profile)
        return {} if object.blank?
        methods = _attributes[profile.to_sym]
        methods.each_with_object({}) do |name_and_options, result|
          method_name, options = name_and_options
          result[method_name] = read_attribute_for_serialization(object, method_name)
        end
      end

      def read_attribute_for_serialization(object, method_name)
        if object.respond_to?(method_name)
          object.send(method_name)
        else
          @object = object # not very correct way to pass object to method..
          self.send(method_name)
        end.to_s
      end

      class << self
        def attributes(*args)
          # we can use
          # self._attributes = _attribute.dup ?
          self._attributes ||= {}
          options = args.last.is_a?(Hash) ? args.pop : {}

          profiles = options.delete(:profile) || [:default]
          profiles = [profiles] unless profiles.is_a?(Array)

          profiles.map(&:to_sym).each do |profile_name|
            self._attributes[profile_name] ||= []
            args.each do |arg_name|
              self._attributes[profile_name] << [arg_name.to_sym, options]
            end
          end
        end
      end
    end
  end
end
