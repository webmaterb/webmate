require 'spec_helper'

def build_packet(data)
  data = {
    params: {
      foo: 'bar',
      metadata: {request_id: 'test'}
    },
    path: '/some/url',
    method: 'GET'
  }.merge(data)
  "3:::#{Webmate::JSON.dump(data)}"
end

describe Webmate::SocketIO::Packets::Base do
  let(:subject) { Webmate::SocketIO::Packets::Base }

  describe "#parse" do
    it "should parse packet data and return object compatible with Sinatra::Request" do
      packet_data = build_packet(path: '/projects')
      request = subject.parse(packet_data)
      request.params[:metadata][:request_id].should == 'test'
      request.method.should == 'GET'
    end
  end
end
