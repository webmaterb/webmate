module Webmate
  class Route
    FIELDS = [:method, :path, :action, :transport, :responder]
    attr_reader *FIELDS

    attr_reader :route_regexp

    def initialize(args)
      values = args.with_indifferent_access
      FIELDS.each do |field_name|
        instance_variable_set("@#{field_name.to_s}", values[field_name])
      end

      construct_match_regexp
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
    #    arguments: { 
    #      project_id: 'qwerty123',
    #      task_id: :asdf13,
    #      comment_id: :zxcv123
    #    }
    #  }
    def match(request_path)
      if match_data = @route_regexp.match(request_path)
        route_data = { action: @action, responder: @responder, attributes: {}}
        @substitution_attrs.each_with_index do |key, index|
          route_data[:attributes][key] = match_data[index.next]
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
      @substitution_attrs = path.scan(/:(\w*_id)/).flatten.map(&:to_sym)
      regexp_string = path.gsub(/:(\w*_id)/) {|t| "([\\w\\d]*)" }
      @route_regexp = Regexp.new("^#{regexp_string}\/?$")
    end
  end
end
