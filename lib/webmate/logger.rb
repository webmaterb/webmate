module Webmate
  class Logger < Rack::CommonLogger
    cattr_accessor :logger_file
    def initialize(app = nil)
      @app = app
      Dir.mkdir(configatron.logger.path) unless File.exists?(configatron.logger.path)
      @@logger_file ||= File.new(File.join(configatron.logger.path, "#{Webmate.env}.log"), 'a')
    end

    def log(env, status, header, began_at)
      dump(%Q{HTTP #{env["REQUEST_METHOD"]}: #{env["PATH_INFO"]} #{status} \nParams: #{env['rack.request.query_hash']}})
    end

    def dump(text)
      [@@logger_file, STDOUT].each do |out|
        out.write %Q{[#{Time.now.strftime("%D %H:%M:%S")}] #{text} \n\n}
      end
    end

    def flush
      @@logger_file.flush
    end
  end
end
