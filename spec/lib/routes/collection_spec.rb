require 'spec_helper'

class FooResponder; end
class ProjectsResponder; end

describe Webmate::Routes::Collection do

  let(:subject) { Webmate::Routes::Collection.new }

  describe "#define" do
    context "responder and action from params" do
      it "should allow setting responder and action using params" do
        subject.define do
          get '/projects', responder: FooResponder, action: 'bar'
        end
        route = subject.match('GET', 'HTTP', '/projects')
        route[:responder].should == FooResponder
        route[:action].should == 'bar'
      end

      it "should allow setting responder and action using :to option" do
        subject.define do
          get '/projects', to: 'foo#bar'
        end
        route = subject.match('GET', 'HTTP', '/projects')
        route[:responder].should == FooResponder
        route[:action].to_s.should == 'bar'
      end
    end

    context "responder and action by resource scope" do
      before do
        subject.define do
          resources :projects
        end
      end

      it "index action" do
        route = subject.match('GET', 'HTTP', '/projects')
        route[:responder].should == ProjectsResponder
        route[:action].to_s.should == 'read_all'
      end

      it "show action" do
        route = subject.match('GET', 'HTTP', '/projects/1')
        route[:responder].should == ProjectsResponder
        route[:action].to_s.should == 'read'
      end
    end
  end

  describe "#match" do
    before do
      subject.define do
        get '/foo', responder: FooResponder, action: 'bar'
        resources :projects, transport: [:http]
      end
    end

    it "should return matched route" do
      subject.match('GET', 'HTTP', '/foo').should_not be_nil
      subject.match('GET', 'WS', '/foo').should_not be_nil
    end

    it "should return route only for matched transport" do
      subject.match('GET', 'HTTP', '/projects/1').should_not be_nil
      subject.match('GET', 'WS', '/projects/1').should be_nil
    end

    it "should return nil if no route found" do
      subject.match('GET', 'HTTP', '/bar').should be_nil
      subject.match('GET', 'WS', '/bar').should be_nil
    end
  end
end
