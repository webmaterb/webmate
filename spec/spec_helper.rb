dir = File.expand_path(File.dirname(__FILE__))

WEBMATE_ROOT = File.join(dir, '..')

SPECDIR = dir
$LOAD_PATH.unshift("#{dir}/../lib")

require 'rubygems'
#require 'mocha'
#require 'rspec'
#require 'facter'
#require 'fileutils'

require File.join(dir, '..', 'lib', 'webmate.rb')

RSpec.configure do |config|
  #config.mock_with :mocha
end
