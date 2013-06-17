module Webmate
  module Documents
    class MongoDocument
      def initialize(attrs = {})
        cleaned_attrs = attrs.select do |key, value|
          self.class.defined_attributes.keys.include?(key.to_s)
        end
        @attributes = cleaned_attrs
      end

      def save(attrs = {})
        @attributes.update(attrs)
        @attributes["_id"] ||= Moped::BSON::ObjectId.new
        self.class.collection.insert(@attributes)
      end

      def attributes
        @attributes ||= {}
      end

      def id
        _id = @attributes["_id"]
        _id.present? ? Moped::BSON::ObjectId.from_string(_id) : nil
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
          defined_attributes[name.to_s] = options
          define_method name do
            attributes[name.to_s]
          end 

          define_method "#{name}=" do |new_val|
            attributes[name.to_s] = new_val
          end 
        end

        def defined_attributes
          @defined_attributes ||= {
            '_id' => { 'type' => 'object_id'},
            'id'  => { 'type' => 'object_id'}
          }
        end

        # update selector with setted types
        def build_mongo_condition(selector = {})
          if selector.is_a?(String) || selector.is_a?(Moped::BSON::ObjectId)
            selector = { '_id' => selector }
          end
          selector.stringify_keys!
          selector['_id'] = selector.delete('id') if selector['id']

          {}.tap do |conditions|
            selector.each do |key, value|
              if attribute_definition = defined_attributes[key]
                if attribute_definition['type'].to_s == 'object_id' && value.is_a?(String)
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
          documents = [documents] unless document.is_a?(Array)
          collection.insert(documents, flags = {})
          documents
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
