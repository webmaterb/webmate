dir = File.expand_path(File.dirname(__FILE__))

WEBMATE_ROOT = File.join(dir, '..')

SPECDIR = dir 
$LOAD_PATH.unshift("#{dir}/../lib")

require 'rubygems'
require 'moped'

require File.join(dir, '..', 'lib', 'webmate.rb')

Webmate::Documents::MongoDocument.load!(
  'hosts'     => ['localhost:27017'],
  'database'  => 'workmate_test'
)

RSpec.configure do |config|
  #config.mock_with :mocha
end
