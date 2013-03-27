class Webmate::SocketIO::Packets::Noop < Webmate::SocketIO::Packets::Base
  def packet_type
    'noop'
  end
end
