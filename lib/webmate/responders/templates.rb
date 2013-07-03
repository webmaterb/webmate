module Webmate::Responders
  module Templates
    extend ActiveSupport::Concern

    module ClassMethods
      def helper(argument)
        if argument.class.name == 'Module'
          Webmate::Views::Scope.send(:include, argument)
        end
      end
    end


    def slim(template, options = {}, locals = {}, &block)
      render(:slim, template, options, locals, &block)
    end

    private 

    def template_cache
      @cache ||= Webmate::Application.template_cache
    end

    def scope
      @scope ||= Webmate::Views::Scope.new(self)
    end

    def render(engine, data, options = {}, locals = {}, &block)
      views     = Webmate::Application.views
      layouts   = Webmate::Application.layouts

      # compile and render template
      template        = compile_template(engine, data, options, views)
      output          = template.render(scope, locals, &block)

      layout = options.delete(:layout) || false
      if layout
        layout_template = compile_template(engine, layout, options, layouts)
        output          = layout_template.render(scope, locals) { output }
      end

      output
    end

    def compile_template(engine, data, options, views)
      template_cache.fetch engine, data, options, views do
        template = Tilt[engine]

        # find template ./views  /name /action_name  engine_name
        file = find_template(views, data, engine)

        template.new(file)
      end
    end

    # search through all available paths
    # [./views/]name.[extension].[engine]/
    # this will not search for responder's custom  folder
    # responder
    def find_template(views, name, engine)
      responder_folder = self.class.name.underscore.sub(/_responder$/, '') # => namespace/responder_name

      # NOTE: we can add shared, and other paths from settings
      folders_to_search = [File.join(views, responder_folder, "*.#{engine.to_s}")]
      folders_to_search << File.join(views, "*.#{engine.to_s}") 

      search_regexp = /\/#{name}[\w|\.]*.#{engine}$/
      Dir[*folders_to_search].each do |file_path|
        return file_path if search_regexp.match(file_path)
      end
      raise TemplateNotFound.new
    end
  end
end
