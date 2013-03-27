class Webmate::SocketIO::Packets::Disconnect < Webmate::SocketIO::Packets::Base
  def packet_type
    'disconnect'
  end
end
