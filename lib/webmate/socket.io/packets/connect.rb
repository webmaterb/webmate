class Webmate::SocketIO::Packets::Connect < Webmate::SocketIO::Packets::Base
  def packet_type
    'connect'
  end
end
