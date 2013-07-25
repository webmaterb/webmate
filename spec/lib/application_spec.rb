require 'spec_helper'

class FooResponder; end

describe Webmate::Application do

  let(:subject) { Webmate::Application }

  describe "#define_routes" do
    context "responder and action from params" do
      it "should define applicatio routes" do
        subject.define_routes do
          get '/projects', responder: FooResponder, action: 'bar'
        end
        route = subject.routes.match('GET', 'HTTP', '/projects')
        route[:responder].should == FooResponder
      end
    end
  end
end
