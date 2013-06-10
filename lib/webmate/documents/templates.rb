require 'active_support/concern'

module Webmate
  module Documents
    module Templates
      #extend ActiveSupport::Concern
  
      def self.included(base)
        base.send(:attribute, 'fields')
        base.extend ClassMethods
      end

      def assign_system_fields
        self.fields = self.class.system_fields.merge(self.fields || {})
      end

      # store embedded templates fields
      def template_fields(template_name)
        attributes['template_fields'] ||= {}
        attributes['template_fields'][template_name.to_s] ||= {}
      end

      # define methods:
      #   embedded_template
      #   field : setup predefined field
      module ClassMethods
        # create place for given template
        # and use it's default
        # embedded_template :tasks_template
        def embedded_template(name, options = {})
          options.stringify_keys!
          name = name.to_s
          raise "Template class not specified" if name.blank?
          template_class_name = (options['template_class'] || name).to_s.classify
          define_method name do
            template_object = instance_variable_get("@#{name}")
            if !template_object
              template_object = template_class_name.constantize.new(template_fields(name))
              instance_variable_set("@#{name}", template_object)
            end
            return template_object
          end
        end

        def field(name, options = {})
          name = name.to_s
          raise "Field name not specified" if name.blank?
          raise "Already defined field #{name} for self" if system_fields[name].present?

          options = {
            'type' => 'string'
          }.merge(options.stringify_keys)
          options['system'] = true

          system_fields[name] = options
        end

        def system_fields
          @system_fields ||= {}
        end
      end
    end
  end
end
