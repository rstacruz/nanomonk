module Nano::MonkActions
  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    def add_config_file(fname)
      @config_files ||= Array.new
      @config_files << "#{root_path}/#{fname}"
    end

    def config_files
      defined?(@config_files) ? @config_files : []
    end

    def root_path(*args)
      return @@root_path  if defined?(@@root_path)
      path = File.dirname(__FILE__)
      old_path = nil

      while path != old_path
        if File.exists?(File.join(path, 'init.rb'))
          return (@@root_path = path)
        end

        old_path = path
        path = File.expand_path(File.join(path, '..'))
      end
      @@root_path = ''
    end
  end

private

  def root_path(*a)
    self.class.root_path(*a)
  end

  def target_file_for(example_file)
    example_file.sub(".example", "")
  end

  def verify_config(env)
    self.class.config_files.each { |f| verify(f.gsub('%{env}', env)) }
  end

  def verify(example)
    copy_example(example) unless File.exists?(target_file_for(example))
  end

  def copy_example(example, target = target_file_for(example))
    return  if File.exists?(target)
    File.exists?(example) ? copy_file(example, target) : say_status(:creating, target)
  end
end
