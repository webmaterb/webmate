# TODO: this is needed to use latest mongoid with moped, but it doesn't work at this moment

begin
  require "moped"
rescue LoadError => error
  raise "Missing EM-Synchrony dependency: gem install moped"
end

module Moped
  class TimeoutHandler
    def self.timeout(op_timeout, &block)
      f = Fiber.current
      timer = EM::Timer.new(op_timeout) { f.resume(nil) }
      res = block.call
      timer.cancel
      res
    end
  end
  module Sockets
    module Connectable
      module ClassMethods
        def connect(host, port, timeout)
          TimeoutHandler.timeout(timeout) do
            sock = new(host, port)
            #sock.set_encoding('binary')
            #sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
            sock
          end
        end
      end
    end

    class EM_TCP < ::EventMachine::Synchrony::TCPSocket
      include Connectable

      def connection_completed
        @opening = false
        @in_req.succeed(self) if @in_req
      end
    end
    Mutex = ::EventMachine::Synchrony::Thread::Mutex
    ConditionVariable = ::EventMachine::Synchrony::Thread::ConditionVariable
  end
  class Connection
    def connect
      @sock = if !!options[:ssl]
        Sockets::SSL.connect(host, port, timeout)
      else
        Sockets::EM_TCP.connect(host, port, timeout)
      end
    end
  end
end