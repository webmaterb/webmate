class Webmate::SocketIO::Packets::Ack < Webmate::SocketIO::Packets::Base
  def packet_type
    'ack'
  end
end
