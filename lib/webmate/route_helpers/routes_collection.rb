module Webmate
  class RoutesCollection

    attr_reader :routes

    # options is configatron.websockets part
    #   enabled:
    #   port:
    #   namespace:
    def initialize(options = {})
      @routes = {}
      @resource_scope = []

      parse_options(options)

      enable_websockets_support if websockets_enabled?
    end

    def define_routes(&block)
      instance_eval(&block)
    end

    # get info about matched route
    #   method    - GET/POST/PUT/PATCH/DELETE
    #   transport - HTTP / WS [ HTTPS / WSS ]
    #   path      - /projects/123/tasks
    #
    def match(method, transport, path)
      routes = get_routes(method, transport)
      routes.each do |route|
        if info = route.match(path)
          return info
        end
      end
      nil
    end

    def get_routes(method, transport)
      @routes[method] ||= {}
      @routes[method][transport] || []
    end

    private

    # if websockets enabled, we should add specific http routes
    #   - for handshake          [ get session id ]
    #   - for connection opening [ switch protocol from http to ws ]
    def enable_websockets_support
      route_options = { method: 'GET', transport: ['HTTP'], action: 'websocket' }

      # handshake
      add_route(Webmate::Route.new(route_options.merge(
        path: "#{websockets_namespace}/:version_id",
        responder: Webmate::SocketIO::Actions::Handshake,
      )))

      # transport connection
      add_route(Webmate::Route.new(route_options.merge(
        transport: ["WS"],
        path: "#{websockets_namespace}/:version_id/websocket/:session_id",
        responder: Webmate::SocketIO::Actions::Connection,
        action: 'open'
      )))
    end

    # we store routes in following structure
    # { method:
    #     transport: [ routes ]
    # route - valid object of Webmate::Route class
    def add_route(route)
      # add route to specific node of routes hash
      @routes[route.method.to_s.upcase] ||= {}
      route.transport.each do |transport|
        (@routes[route.method.to_s.upcase][transport.to_s.upcase] ||= []).push(route)
      end
    end

    # define methods for separate routes
    #   get '/path', to: , transport: ,
    # or 
    #   resources :projects
    #     member do
    #       get 'read_formatted'
    %w[get post put delete patch].each do |method_name|
      define_method method_name.to_sym do |path, options = {}|
        route_options = process_options(options)

        # process case inside resources/collection or resources/member block
        if is_member_scope? or is_collection_scope?
          route_options[:responder] ||= get_responder_from_scope
          route_options[:action] ||= path
          route_options[:path] ||= path
        else
          route_options[:path] = path || '/'
        end
        route_options[:method] = method_name.to_sym

        add_route(Webmate::Route.new(route_options))
      end
    end

    # available options are
    # transport: [:http, :ws] or any single transport
    # responder can be specified
    #   action: some_action
    #   responder: SomeResponder or 'some/responder/api/v1'
    # or with to: param
    #   to: 'responder_name#action_name'
    def process_options(raw_options)
      options = {}
      options[:transport] = normalized_transport_option(raw_options[:transport])

      if responder_with_action = raw_options[:to]
        # extract action & responder from :to
        responder_name, action = responder_with_action.split('#')
        options[:responder] = "#{responder_name}_responder".classify.constantize
        options[:action] = action
      else
        # use action & responder options
        options[:responder] = raw_options[:responder]
        options[:action] = raw_options[:action]
      end

      options
    end

    # resource :name, options, &block
    #  can register following methods
    #     get 'name'        => read_all
    #     get 'name/:id'    => read
    #     post 'name'       => create
    #     put 'name/:id'    => update
    #     delete 'name/:id' => destroy
    #
    # examples
    #   resources :projects, transport: :http, only: [:read, :read_all, :update, :delete, :create]
    #
    def resources(*resources, &block)
      options = resources.last.is_a?(Hash) ? resources.pop : {}
      actions = normalized_action_option(options.delete(:only))

      resources.each do |resource_name|
        if (responder = options[:responder]).blank?
          responder = scope_namespace + "#{resource_name}_responder".classify
        end

        route_args = { responder: responder, transport: options[:transport]}

        [:read, :read_all, :update, :delete, :create].each do |action_name|
          responder_action = options[:action] || action_name
          if actions.include?(action_name)
            self.send "define_resource_#{action_name}_method",
              resource_name.to_s,
              route_args.merge(action: responder_action.to_s)
          end
        end

        nested_resources_eval(resource_name, &block) if block_given?
      end
    end

    def namespace(name, &block)
      @resource_scope.push({ namespace: name })
      collection &block
    ensure
      @resource_scope.pop
    end

    # should process blocks inside other resource
    #   and correctly set prefix of resources-parents
    #   resourcesprojects do
    #     resources :tasks
    #   end
    def nested_resources_eval(resource_name, &block)
      @resource_scope.push({
        resource: resource_name,
        resource_id: "#{resource_name.to_s.singularize}_id".to_sym
      })
      yield block
    ensure
      @resource_scope.pop
    end

    def path_prefix
      prefix = ''
      @resource_scope.each do |scope|
        if scope[:namespace]
          prefix << "/#{scope[:namespace]}"
        else
          prefix << "/#{scope[:resource]}"
          prefix << "/:#{scope[:resource_id]}" unless scope[:collection]
        end
      end
      prefix
    end

    def get_responder_from_scope
      responder_name = @resource_scope.last[:resource]
      "#{scope_namespace}#{responder_name}_responder".classify.constantize
    end

    def scope_namespace
      namespace = ''
      @resource_scope.each do |scope|
        namespace += "#{scope[:namespace].to_s.classify}::"
      end
      namespace
    end

    # methods below designed to set actions on member/collection
    # inside resource definition block
    #
    # "projects/do_on_collection"
    # "projects/:project_id/do_on_member"
    #
    # can be designed as
    # example
    # resources :projects do
    #   collection do
    #     get 'do_on_collection'
    #   end
    #
    #   member do
    #     get "do_on_member"
    #   end 
    #   prefix /resource_name/resource_id
    def member(&block)
      return if @resource_scope.blank?
      @resource_scope.last[:member] = true
      yield block
    ensure
      @resource_scope.last[:member] = false
    end

    # prefix /resource_name
    def collection(&block)
      return if @resource_scope.blank?
      @resource_scope.last[:collection] = true
      yield block
    ensure
      @resource_scope.last[:collection] = false
    end

    # track definition inside collection block
    # collection do
    #   path 'code', options
    def is_collection_scope?
      @resource_scope.present? && @resource_scope.last[:collection]
    end

    # track definition inside member block
    # collection do
    #   path 'code', options
    def is_member_scope?
      @resource_scope.present? && @resource_scope.last[:member]
    end

    def is_namespace_scope?
      @resource_scope.present? && @resource_scope.last[:namespace]
    end

    # helper methods
    # normalize_transport_option 
    #   returns array of requested transports, but available ones only
    def normalized_transport_option(transport = nil)
      return transports.dup if transport.blank?
      transport = [transport] unless transport.is_a?(Array)

      transport.map{|t| t.to_s.downcase.to_sym} & transports
    end

    # methods list
    #   combination from available
    #   [:read, :read_all, :update, :delete, :create]
    def normalized_action_option(methods = nil)
      default_methods = [:read, :read_all, :update, :delete, :create]
      return default_methods if methods.blank?
      methods = [methods] unless methods.is_a?(Array)

      methods.map{|m| m.to_s.downcase.to_sym} & default_methods
    end

    def define_resource_read_all_method(resource_name, route_args) 
      get "#{path_prefix}/#{resource_name}", route_args
    end

    def define_resource_read_method(resource_name, route_args)
      get "#{path_prefix}/#{resource_name}/:#{resource_name.singularize}_id", route_args
    end

    def define_resource_create_method(resource_name, route_args)
      post "#{path_prefix}/#{resource_name}", route_args
    end

    def define_resource_update_method(resource_name, route_args)
      put "#{path_prefix}/#{resource_name}/:#{resource_name.singularize}_id", route_args
    end

    def define_resource_delete_method(resource_name, route_args)
      delete "#{path_prefix}/#{resource_name}/:#{resource_name.singularize}_id", route_args
    end

    # options parts
    def parse_options(options = {})
      default_options = {
        enabled: true,
        port: 80,
        namespace: 'api'
      }

      @options = default_options.merge(options.symbolize_keys)
    end

    def websockets_enabled?
      @options[:enabled]
    end

    def websockets_namespace
      @options[:namespace] || 'api'
    end

    def transports
      @transports ||= (websockets_enabled? ? [:ws, :http] : [:http])
    end
  end
end
