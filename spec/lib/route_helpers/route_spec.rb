require 'spec_helper'

class TestResponder
end

def build_route_for(path, action = "any", responder = "test_responder")
  route_args = {
    method: "any",
    transport: "transport",
  }.merge(
    path: path,
    action: action,
    responder: responder
  )

  Webmate::Route.new(route_args)
end

describe Webmate::Route do
  it "should match simple routes" do
    result = build_route_for('/projects').match("/projects")
    result.should_not be_nil
  end

  it "should match empty routes" do
    result = build_route_for('/').match("/")
    result.should_not be_nil
  end

  it "should match routes with placements" do
    result = build_route_for('/projects/:project_id').match("/projects/qwerty")
    result.should_not be_nil
    result[:params][:project_id].should == 'qwerty'
  end

  it "should match routes with wildcards" do
    pending "feature not yet implemented"
  end
end
