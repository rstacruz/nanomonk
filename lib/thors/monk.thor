class Monk < Thor
  desc "start ENV", "Start Monk in the supplied environment"
  def start(env = ENV["RACK_ENV"] || "development")
    verify_config(env)

    cmd = "env RACK_ENV=#{env} ruby init.rb"
    say_status :run, cmd
    exec cmd
  end

  desc "copy_example EXAMPLE, TARGET", "Copies an example file to its destination"
  def copy_example(example, target = target_file_for(example))
    return  if File.exists?(target)
    File.exists?(example) ? copy_file(example, target) : say_status(:missing, example)
  end

private
  def self.root_path
    File.expand_path(File.dirname(__FILE__), '../..')
  end

  def self.add_config_file(fname)
    @@config_files ||= Array.new
    @@config_files << "#{root_path}/#{fname}"
  end

  add_config_file 'config/appconfig.example.yml'
end
