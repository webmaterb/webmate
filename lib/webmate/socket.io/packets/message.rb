class Webmate::SocketIO::Packets::Message < Webmate::SocketIO::Packets::Base
  def packet_type
    'message'
  end
end
