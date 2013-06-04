module Webmate
  module Documents
    class MongoDocument
      def initialize(attrs = nil)
        @attributes = attrs || {}
      end

      def save(attrs = {})
        @attributes.update(attrs)
        self.class.collection.insert(@attributes)
      end

      def attributes
        @attributes ||= {}
      end
      
      #def method_missing(method_name, *args, &block)
      #  define_method(method_name) { return @attributes[method_name.to_sym] }
      #end

      # add moped proxy for object search?
      class << self
        def find(*args)
          collection.find(*args).map{|attrs| new(attrs)}
        end

        def insert(*args)
          collection.insert(*args)
        end

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
