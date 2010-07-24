ROOT_DIR = File.expand_path(File.dirname(__FILE__)) unless defined? ROOT_DIR

require "rubygems"
require "./vendor/dependencies/lib/dependencies"
require "monk/glue"

class Main < Monk::Glue
  set     :app_file, __FILE__
  use     Rack::Session::Cookie
end #class

Dir['app/**/*.rb'].each { |f| require f }
Main.run!  if Main.run?
