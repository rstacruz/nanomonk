ENV['RACK_ENV'] = 'test'
require File.join(File.dirname(__FILE__), '..', 'init.rb')

require 'rack/test'

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Main.new
  end

  def setup
  end #setup
end #class
