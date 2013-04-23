module Webmate::Responders
  module Templates
    def self.included(base)
      base.class_eval do
        attr_reader :template_cache
        attr_reader :settings
      end
    end

    def initialize(*args)
      super

      #TODO this should be fetched from application
      @settings = OpenStruct.new(
        views: 'app/views',
        layouts: 'app/views/layouts'
      )
      @template_cache = Tilt::Cache.new
    end

    def slim(template, options = {}, locals = {}, &block)
      render(:slim, template, options, locals, &block)
    end

    private 

    # layout = Slim::Template.new(layout_file)
    # content = Slim::Template.new(content_file).render(scope)
    # layout.render(scope) { c }

    def render(engine, data, options = {}, locals = {}, &block)
      views   = settings.views
      layouts = settings.layouts

      scope = Webmate::Responders::RenderingScope.new(self)
      layout = options.delete(:layout) || false

      # compile and render template
      template        = compile_template(engine, data, options, views)
      output          = template.render(scope, locals, &block)

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
      folders_to_search = [File.join(WEBMATE_ROOT, views, responder_folder, "*.#{engine.to_s}")]
      folders_to_search << File.join(WEBMATE_ROOT, views, "*.#{engine.to_s}") 

      search_regexp = /\/#{name}[\w|\.]*.#{engine}$/
      Dir[*folders_to_search].each do |file_path|
        return file_path if search_regexp.match(file_path)
      end
      raise TemplateNotFound.new
    end
  end
end
