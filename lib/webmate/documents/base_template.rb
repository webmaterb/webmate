module Webmate
  class BaseTemplate < Webmate::Documents::MongoDocument
    include Webmate::Documents::Templates
    include Webmate::Documents::CustomFields

    def initialize(attributes = {})
      attributes.stringify_keys!
      custom_fields = attributes.delete('fields') || {}
      super(attributes)
      assign_system_fields
      fields.update(custom_fields.stringify_keys)
    end
  end
end

