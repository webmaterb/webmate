require 'spec_helper'

class PagesResponder; end
class ProjectsResponder; end
class TasksResponder; end

def validate_route(route, responder_class, action_name, params = {})
  route[:responder].should eq(responder_class)
  route[:action].should eq(action_name)
  params.each do |key, value|
    route[:params][key].should eq(value)
  end
end

describe "Webmate::RoutesCollection" do
  describe "routes definition" do
    let (:router) { Webmate::RoutesCollection.new(enabled: true) }

    it "simple GET route" do
      router.define_routes { get '/projects', to: 'projects#read', transport: [:http] }
      route = router.match('GET', 'HTTP', 'projects')
      validate_route(route, ProjectsResponder, 'read')
    end

    it "simple POST route" do
      router.define_routes { post '/projects', to: 'projects#create', transport: [:ws] }
      route = router.match('POST', 'WS', 'projects')
      validate_route(route, ProjectsResponder, 'create')
    end

    it "simple PUT route" do
      router.define_routes { put '/projects/:project_id', to: 'projects#update', transport: [:http] }
      route = router.match('PUT', 'HTTP', 'projects/123')
      validate_route(route, ProjectsResponder, 'update', { project_id: '123'})
    end

    it "simple DELETE route" do
      router.define_routes { delete '/projects/:project_id', to: 'projects#destroy', transport: [:ws] }
      route = router.match('DELETE', 'WS', 'projects/123')
      validate_route(route, ProjectsResponder, 'destroy', { project_id: '123'})
    end
  end

  describe "websockets connection methods" do
    let (:namespace) { 'test-websockets-prefix' }
    let (:version_id) { '123' }
    let (:session_id) { SecureRandom.hex }
    let (:router) { Webmate::RoutesCollection.new(enabled: true, namespace: namespace) }

    it "should be disableable" do
      router = Webmate::RoutesCollection.new(enabled: false)
      router.routes.should be_blank
    end

    it "should define handshake" do
      route = router.match('GET', 'HTTP', "#{namespace}/#{version_id}")

      validate_route(
        route, Webmate::SocketIO::Actions::Handshake, 'websocket', 
        { :version_id => version_id }
      )
    end

    # responder and action doesn't matter
    it "should define connect" do
      route = router.match('GET', 'WS', "#{namespace}/#{version_id}/websocket/#{session_id}")

      validate_route(
        route, Webmate::SocketIO::Actions::Connection, 'open', 
        { :version_id => version_id, :session_id => session_id }
      )
    end
  end

  describe "resources" do
    
    context "full" do
      before :all do
        @router = Webmate::RoutesCollection.new(enabled: true)
        @transports = ['HTTP', 'WS']
        @router.define_routes do 
          resources :projects, transport: [:ws, :http]
        end
      end

      it "should define read_all" do
        @transports.each do |transport|
          route = @router.match("GET", transport, '/projects')
          validate_route(route, ProjectsResponder, 'read_all')
        end
      end

      it "should define read" do
        @transports.each do |transport|
          route = @router.match("GET", transport, '/projects/123')
          validate_route(route, ProjectsResponder, 'read', { project_id: '123' })
        end
      end

      it "should define create" do
        @transports.each do |transport|
          route = @router.match("POST", transport, '/projects')
          validate_route(route, ProjectsResponder, 'create')
        end
      end

      it "should define update" do
        @transports.each do |transport|
          route = @router.match("PUT", transport, '/projects/123')
          validate_route(route, ProjectsResponder, 'update', { project_id: '123'})
        end
      end

      it "should define destroy" do
        @transports.each do |transport|
          route = @router.match("DELETE", transport, '/projects/123')
          validate_route(route, ProjectsResponder, 'delete', { project_id: '123'})
        end
      end
    end

    context "resource options" do
      before :all do
        @router = Webmate::RoutesCollection.new(enabled: true)
        @router.define_routes do
          resources :projects, 
            transport: [:http], 
            only: [:read, :read_all], 
            responder: 'PagesResponder',
            action: 'index'
        end
      end

      it "should use 'transport' option" do
        @router.match('GET', 'HTTP', 'projects').should_not be_blank
        @router.match('GET', 'HTTP', 'projects/123').should_not be_blank

        @router.match('GET', 'WS', 'projects').should be_blank
        @router.match('GET', 'WS', 'projects/123').should be_blank
      end

      it "should use 'only' option" do
        @router.match('GET', 'HTTP', 'projects').should_not be_blank
        @router.match('GET', 'HTTP', 'projects/123').should_not be_blank
        @router.match('POST', 'HTTP', 'projects').should be_blank
        @router.match('PUT', 'HTTP', 'projects/132').should be_blank
        @router.match('DELETE', 'HTTP', 'projects/123').should be_blank
      end

      it "should use 'responder' and action option" do
        route = @router.match('GET', 'HTTP', 'projects')
        validate_route(route, PagesResponder, 'index')

        route = @router.match('GET', 'HTTP', 'projects/123')
        validate_route(route, PagesResponder, 'index')
      end
    end

    # example of usage for nested
    context "nested methods and resources" do
      before :all do
        @router =  Webmate::RoutesCollection.new(enabled: true) 
        @router.define_routes do
          resources :projects, only: [], transports: [:http] do
            resources :tasks

            get     'get_method', on: :member, action: 'member_action'
            post    'post_method', on: :collection, action: 'collection_method'

            member do
              put     'put_method', action: 'member_action'
            end
            collection do
              delete  'delete_method', action: 'collection_method'
            end
          end
        end

        # methods already test, just check
        # feel free to add tests if there are will be errors
        it "should define nested resources methods" do
          route = @router.match('GET', 'HTTP', 'projects/123/tasks')
          validate_route(route, TasksResponder, 'index')
        end

        it "should define nested route on collection" do
          route = @router.match('POST', 'HTTP', 'projects/post_method')
          validate_route(route, ProjectsResponder, 'collection_method')

          route = @router.match('DELETE', 'HTTP', 'projects/delete_method')
          validate_route(route, ProjectsResponder, 'collection_method')
        end

        it "should define nested route on member" do
          route = @router.match('GET', 'HTTP', 'projects/123/get_method')
          validate_route(route, ProjectsResponder, 'member_action')

          route = @router.match('PUT', 'HTTP', 'projects/123/put_method')
          validate_route(route, ProjectsResponder, 'member_action')
        end
      end
    end
  end
end
