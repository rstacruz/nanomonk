class Monk < Thor
  desc "start ENV", "Start Monk in the supplied environment"
  def start(env = ENV["RACK_ENV"] || "development")
    verify_config(env)

    exec "env RACK_ENV=#{env} ruby init.rb"
  end

  desc "copy_example EXAMPLE, TARGET", "Copies an example file to its destination"
  def copy_example(example, target = target_file_for(example))
    return  if File.exists?(target)
    File.exists?(example) ? copy_file(example, target) : say_status(:missing, example)
  end

private
  
  def self.source_root
    File.dirname(__FILE__)
  end
  
  def self.root_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
  end

  def root_path
    self.class.root_path
  end

  def target_file_for(example_file)
    example_file.sub(".example", "")
  end

  def verify_config(env)
    @@config_files.each { |f| verify(f % { :env => env }) }  unless @@config_files.nil?
  end

  def self.add_config_file(fname)
    @@config_files ||= Array.new
    @@config_files << "#{root_path}/#{fname}"
  end

  def verify(example)
    copy_example(example) unless File.exists?(target_file_for(example))
  end

  add_config_file 'config/appconfig.example.yml'
end
