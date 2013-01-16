module Webmate
  def self.env
    ENV["RACK_ENV"]
  end

  def self.env?(env)
    self.env == env.to_s
  end
end