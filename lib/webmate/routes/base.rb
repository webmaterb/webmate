module Webmate::Routes
  class Base
    FIELDS = [:method, :path, :action, :transport, :responder, :route_regexp, :static_params]
    attr_reader *FIELDS

    # method: GET/POST/PUT/DELETE
    # path  : /user/123/posts/123/comments
    # transport: HTTP/WS/
    # responder: class, responsible to 'respond' action
    # action: method in webmate responders, called to fetch data
    # static params: additional params hash, which will be passed to responder
    #   for example, { :scope => :user }
    #
    def initialize(args)
      values = args.with_indifferent_access
      FIELDS.each do |field_name|
        instance_variable_set("@#{field_name.to_s}", values[field_name])
      end

      normalize_data_if_needed
      @route_regexp ||= construct_match_regexp
    end

    # method should check coincidence of path pattern and
    # given path
    # '/projects/qwerty123/tasks/asdf13/comments/zxcv123'
    # will be parsed with route
    # /projects/:project_id/tasks/:task_id/comments/:comment_id
    # and return
    #  result = {
    #    action: 'read',
    #    responder: CommentsResponder,
    #    params: {
    #      project_id: 'qwerty123',
    #      task_id: :asdf13,
    #      comment_id: :zxcv123
    #    }
    #  }
    def match(request_path)
      if match_data = @route_regexp.match(request_path)
        route_data = {
          action: @action,
          responder: @responder,
          params: HashWithIndifferentAccess.new(static_params || {})
        }
        @substitution_attrs.each_with_index do |key, index|
          if key == :splat
            route_data[:params][key] ||= []
            route_data[:params][key] += match_data[index.next].split('/')
          else
            route_data[:params][key] = match_data[index.next]
          end
        end
        route_data
      else
        nil # not matched.
      end
    end

    private

    # /projects/:project_id/tasks/:task_id/comments/:comment_id
    # result should be
    # substitution_attrs = [:project_id, :task_id, :comment_id]
    # route_regexp =
    #   (?-mix:^\/projects\/([\w\d]*)\/tasks\/([\w\d]*)\/comments\/([\w\d]*)\/?$)
    #
    # substitute :resource_id elements with regexp group in order
    # to easy extract
    def construct_match_regexp
      substitutions = path.scan(/\/:(\w*)|\/(\*)/)
      @substitution_attrs = substitutions.each_with_object([]) do |scan, attrs|
        if scan[0]
          attrs << scan[0].to_sym
        elsif scan[1]
          attrs << :splat
        end
      end
      regexp_string = path.gsub(/\/:(\w*_id)/) {|t| "/([\\w\\d]*)" }
      regexp_string = regexp_string.gsub(/\/\*/) {|t| "\/(.*)"}
      Regexp.new("^#{regexp_string}\/?$")
    end

    # update attributes by following rules
    # - responder should be a Class, not String
    # - ..
    def normalize_data_if_needed
      @responder = @responder.to_s.classify.constantize unless @responder.is_a?(Class)
    end
  end
end
