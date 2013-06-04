module Webmate
  module Documents
    module CustomFields
      def clear_field_options(options = {})
        options.symbolize_keys!
        options.delete(:system)
        options.delete(:hide)
        options
      end

      def add_field(name, fields_options = {})
        name = name.to_sym
        if fields[name]
          raise "Field #{name.to_s} already defined with #{fields[name].inspect}"
        else
          fields[name] = clear_field_options(fields_options)
        end
        fields
      end

      def update_field(name, field_options)
        fields[name.to_sym].update(clear_field_options(field_options))
      end

      def remove_field(name)
        name = name.to_sym
        field = fields[name]
        return nil if field.nil? # blank can be used for default value

        if field[:system]
          field[:hide] = true
        else 
          fields.delete(name.to_sym)
        end
      end

      def remove_fields
        fields.keys.each do |field_name|
          remove_field(field_name)
        end
      end

      def update_fields(new_fields)
        new_fields.each do |field_name, field_options|
          update_field(field_name, field_options)
        end
      end
    end
  end
end
