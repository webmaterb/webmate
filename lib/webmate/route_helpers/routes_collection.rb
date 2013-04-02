module Webmate
  class RoutesCollection
    TRANSPORTS = [:ws, :http]

    attr_reader :routes

    def initialize
      @routes = {}
      @resource_scope = []
    end

    def define_routes(&block)
      instance_eval(&block)
    end

    private

    # we store routes in following structure
    # { method:
    #     transport: [ routes ]
    # route - valid object of Webmate::Route class
    def add_route(route)
      # add route to specific node of routes hash
      @routes[route.method] ||= {}
      route.transport.each do |transport|
        (@routes[route.method][transport] ||= []).push(route)
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
        # process case inside resources/collection or resources/member block
        if options.blank? && @resource_scope.present?
          route_options = {
            responder: get_responder_from_scope,
            action: path,
            path: "#{path_prefix}/#{path}",
            transport: normalized_transport_option(nil)
          }
        else
          route_options = process_options(options)
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
        responder = (options[:responder] || "#{resource_name}_responder").classify
        route_args = { responder: responder, transport: options[:transport] }

        [:read, :read_all, :update, :delete, :create].each do |action_name|
          if actions.include?(action_name)
            self.send "define_resource_#{action_name}_method", resource_name.to_s, route_args
          end
        end

        nested_resources_eval(resource_name, &block) if block_given?
      end
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
        prefix << "/#{scope[:resource]}"
        prefix << "/:#{scope[:resource_id]}" unless scope[:collection]
      end

      puts "path_prefix for #{@resource_scope.inspect}"
      puts "is: #{prefix}"
      prefix
    end

    def get_responder_from_scope
      responder_name = @resource_scope.last[:resource]
      "#{responder_name}_responder".classify.constantize
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
      yield block
    end

    # prefix /resource_name
    def collection(&block)
      return if @resource_scope.blank?
      @resource_scope.last[:collection] = true
      yield block
    ensure
      @resource_scope.last[:collection] = false
    end

    # helper methods
    # normalize_transport_option 
    #   returns array of requested transports, but available ones only
    def normalized_transport_option(transport = nil)
      return TRANSPORTS.dup if transport.blank?
      transport = [transport] unless transport.is_a?(Array)

      transport.map{|t| t.to_s.downcase.to_sym} & TRANSPORTS
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
      get "#{path_prefix}/#{resource_name}", route_args.merge(action: :read_all)
    end

    def define_resource_read_method(resource_name, route_args)
      get "#{path_prefix}/#{resource_name}/:#{resource_name.singularize}_id", route_args.merge(action: :read)
    end

    def define_resource_create_method(resource_name, route_args)
      post "#{path_prefix}/#{resource_name}", route_args.merge(action: :create)
    end

    def define_resource_update_method(resource_name, route_args)
      put "#{path_prefix}/#{resource_name}/:#{resource_name.singularize}_id", route_args.merge(action: :update)
    end

    def define_resource_delete_method(resource_name, route_args)
      delete "#{path_prefix}/#{resource_name}/:#{resource_name.singularize}_id", route_args.merge(action: :delete)
    end
  end
end
