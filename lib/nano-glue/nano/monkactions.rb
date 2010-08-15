module Nano::MonkActions
private
  def root_path(*args)
    return @@root_path  if defined?(@@root_path)
    path = File.dirname(__FILE__)
    old_path = nil

    while path != old_path
      return (@@root_path = path)  if File.exists?(File.join(path, 'init.rb'))

      old_path = path
      path = File.expand_path(File.join(path, '..'))
    end
    @@root_path = ''
  end

  def target_file_for(example_file)
    example_file.sub(".example", "")
  end

  def verify_config(env)
    @@config_files.each { |f| verify(f.gsub('%{env}', env)) }  if defined?(@@config_files)
  end

  def verify(example)
    copy_example(example) unless File.exists?(target_file_for(example))
  end
end
