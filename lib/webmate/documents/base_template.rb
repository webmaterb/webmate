module Webmate
  class BaseTemplate < Webmate::Documents::MongoDocument
    include Webmate::Documents::Templates
    include Webmate::Documents::CustomFields

    def initialize(custom_fields = {})
      super()
      fields.update(custom_fields)
      assign_system_fields
    end
  end
end

