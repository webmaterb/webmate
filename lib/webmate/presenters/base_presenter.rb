module Webmate
  class BasePresenter
    include Webmate::Presenters::Scoped

    attr_accessor :accessor, :resources

    def initialize(resources = [])
      @resources = resources.to_a
      @errors = []
    end

    def to_serializable
      build_serialized default_resource do |object|
        attributes object.attributes.keys
      end
    end

    def errors
      @errors
    end

    def to_json(options = {})
      serialize_resource.to_json
    end

    private

    def serialize_resource
      if errors.present?
        serialize_errors
      else
        to_serializable
      end
    end

    def serialize_errors
      build_serialized do
        namespace 'errors' do
          errors.each do |error|
            attribute error.key do
              error.value
            end
          end
        end
      end
    end

    def resource_by_name(name)
      @resources.resource(name.to_sym)
    end

    def default_resource
      @resources
    end
  end
end
