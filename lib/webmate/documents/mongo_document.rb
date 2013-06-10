module Webmate
  module Documents
    class MongoDocument
      def initialize(attrs = {})
        cleaned_attrs = attrs.select do |key, value|
          self.class.defined_attributes.keys.include?(key.to_sym)
        end
        @attributes = cleaned_attrs
      end

      def save(attrs = {})
        @attributes.update(attrs)
        self.class.collection.insert(@attributes)
      end

      def attributes
        @attributes ||= {}
      end

      def id
        Moped::BSON::ObjectId.from_string(@attributes[:_id])
      end
      
#      def method_missing(method_name, *args, &block)
#        # if method_name.to_s[-1] == '='
#        if @attributes.keys.include?(method_name.to_sym)
#          define_method(method_name) { return @attributes[method_name.to_sym] }
#          return @attributes[method_name.to_sym]
#        else
#          super
#        end
#      end

      # add moped proxy for object search?
      class << self
        def attribute(name, options = {})
          defined_attributes[name.to_sym] = options
          define_method name do
            attributes[name.to_sym]
          end 

          define_method "#{name}=" do |new_val|
            attributes[name.to_sym] = new_val
          end 
        end

        def defined_attributes
          @defined_attributes ||= { _id: { type: :object_id}, id: { type: :object_id }}
        end

        # update selector with setted types
        def build_mongo_condition(selector = {})
          selector[:_id] = selector.delete(:id) if selector[:id]

          {}.tap do |conditions|
            selector.symbolize_keys.each do |key, value|
              if attribute_definition = defined_attributes[key]
                if attribute_definition[:type] == :object_id
                  conditions[key] = Moped::BSON::ObjectId.from_string(value)
                else
                  conditions[key] = value
                end
              end
            end
          end
        end

        # should returns proxy object to support chaining
        def find(selector = {})
          collection.find(build_mongo_condition(selector)).map{|attrs| new(attrs)}
        end
        alias :where :find

        def insert(documents, flags = {})
          collection.insert(documents, flags = {})
        end

        def delete_all(selector = {})
          collection.find(build_mongo_condition(selector)).remove_all
        end
        alias :destroy_all :delete_all

        def collection
          collection_name = "#{ActiveSupport::Inflector.underscore(self.name)}s"
          database[collection_name]
        end

        def database
          @database ||= establish_connection
        end

        def establish_connection
          session = Moped::Session.new(settings['hosts'])
          Moped::Database.new(session, settings['database'])
        end

        def load!(settings)
          # check for 'hosts' and 'database' keys?
          @@settings = settings
        end

        def settings
          @@settings || {}
        end
      end
    end
  end
end
