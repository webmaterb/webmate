module Webmate
  def self.root
    WEBMATE_ROOT
  end

  def self.env
    ENV["RACK_ENV"]
  end

  def self.env?(env)
    self.env == env.to_s
  end

  def self.logger
    @logger ||= Webmate::Logger.new
  end
end