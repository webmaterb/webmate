module Webmate::Responders
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveSupport::Callbacks

    included do
      define_callbacks :process_action
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        alias_method :process_action!, :process_action
        def process_action
          run_callbacks(:process_action, action_method) do
            process_action!
          end
        end
      RUBY_EVAL
    end

    module ClassMethods
      def _normalize_callback_options(options)
        if only = options[:only]
          only = Array(only).map {|o| "action_method == '#{o}'"}.join(" || ")
          options[:per_key] = {:if => only}
        end
        if except = options[:except]
          except = Array(except).map {|e| "action_method == '#{e}'"}.join(" || ")
          options[:per_key] = {:unless => except}
        end
      end

      def _insert_callbacks(callbacks, block)
        options = callbacks.last.is_a?(Hash) ? callbacks.pop : {}
        _normalize_callback_options(options)
        callbacks.push(block) if block
        callbacks.each do |callback|
          yield callback, options
        end
      end

      def skip_filter(*names, &blk)
        skip_before_filter(*names)
        skip_after_filter(*names)
        skip_around_filter(*names)
      end

      [:before, :after, :around].each do |filter|
        class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
          # Append a before, after or around filter. See _insert_callbacks
          # for details on the allowed parameters.
          def #{filter}_filter(*names, &blk)
            _insert_callbacks(names, blk) do |name, options|
              options[:if] = (Array.wrap(options[:if]) << "!halted") if #{filter == :after}
              set_callback(:process_action, :#{filter}, name, options)
            end
          end

          # Prepend a before, after or around filter. See _insert_callbacks
          # for details on the allowed parameters.
          def prepend_#{filter}_filter(*names, &blk)
            _insert_callbacks(names, blk) do |name, options|
              options[:if] = (Array.wrap(options[:if]) << "!halted") if #{filter == :after}
              set_callback(:process_action, :#{filter}, name, options.merge(:prepend => true))
            end
          end

          # Skip a before, after or around filter. See _insert_callbacks
          # for details on the allowed parameters.
          def skip_#{filter}_filter(*names, &blk)
            _insert_callbacks(names, blk) do |name, options|
              skip_callback(:process_action, :#{filter}, name, options)
            end
          end

          # *_filter is the same as append_*_filter
          alias_method :append_#{filter}_filter, :#{filter}_filter
        RUBY_EVAL
      end
    end
  end
end