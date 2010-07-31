module Thor::MonkActions
private
  def root_path(*args)
    File.expand_path(File.join(File.dirname(__FILE__), args))
  end

  def target_file_for(example_file)
    example_file.sub(".example", "")
  end

  def verify_config(env)
    @@config_files.each { |f| verify(f.gsub('%{env}', env)) }  unless @@config_files.nil?
  end

  def verify(example)
    copy_example(example) unless File.exists?(target_file_for(example))
  end
end
