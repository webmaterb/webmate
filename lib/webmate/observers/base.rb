module Webmate::Observers
  class Base
    class << self
      cattr_accessor :subscriptions

      def subscribe(action, &block)
        Webmate::Observers::Base.subscribe!(action, &block)
      end

      def subscribe!(action, &block)
        self.subscriptions ||= {}
        self.subscriptions[action] ||= []
        self.subscriptions[action] << block
      end

      def execute_all(action, data)
        self.subscriptions ||= {}
        (self.subscriptions[action] || []).each do |block|
          block.call(data)
        end
      end
    end
  end
end