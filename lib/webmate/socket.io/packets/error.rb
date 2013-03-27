class Webmate::SocketIO::Packets::Error < Webmate::SocketIO::Packets::Base
  def packet_type
    'error'
  end
end
