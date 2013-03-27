class Webmate::SocketIO::Packets::Heartbeat < Webmate::SocketIO::Packets::Base
  def packet_type
    'heartbeat'
  end
end
