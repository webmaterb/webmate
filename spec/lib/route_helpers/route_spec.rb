require 'spec_helper'

# responder to use as param for route creation.
# should not be used for another
class TestResponder; end

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
    route  = build_route_for('/projects/*')
    result = build_route_for('/projects/*').match("/projects/qwerty/code")
  end

  it "should ignore heading '/'" do
    build_route_for('projects').match('/projects')
    build_route_for('/projects').match('projects')
  end

  it "should ignore trailing '/'" do
    result = build_route_for('/projects/').match("/projects")
    result.should_not be_nil
  end

  it "should not mix '/' and data" do
    result = build_route_for('/projects/').match("/projects/123")
    result.should be_nil
  end

end
