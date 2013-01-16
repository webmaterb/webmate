module Thin
  module Backends
    class Base
      def start
        @stopping = false
        starter   = proc do
          connect
          @running = true
        end
        EventMachine.synchrony(&starter)
      end
    end
  end
end