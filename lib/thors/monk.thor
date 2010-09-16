require File.expand_path(File.join(File.dirname(__FILE__), '../nano-glue/nano.rb'))

class Monk < Thor
  include Nano::MonkActions

  desc "start ENV", "Start Monk in the supplied environment"
  def start(env = ENV["RACK_ENV"] || "development")
    verify_config(env)

    cmd = "env RACK_ENV=#{env} ruby init.rb"
    say_status :run, cmd
    exec cmd
  end

private
  add_config_file 'config/appconfig.example.yml'
end
