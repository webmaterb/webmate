module Webmate
  class Route
    FIELDS = [:method, :path, :action, :transport, :responder]
    attr_reader *FIELDS

    def initialize(args)
      values = args.with_indifferent_access
      FIELDS.each do |field_name|
        instance_variable_set("@#{field_name.to_s}", values[field_name])
      end

      #validate!
    end

    def validate
      # check
    end
  end
end
