# To do:
#  monk add less
#  monk gem less
#
require 'thor'

module Nano
  module Actions
    def I(str)
      reindent(str)
    end

    def reindent(str)
      str = str[1..-1]  if str[0] == "\n" # Remove first newline
      str.gsub!(/^#{str.match(/^\s*/)[0]}/, '') # Unindent
      str += "\n"  unless str[-1] == "\n" # Ensure last newline
      str
    end

    def append_file_p(file, str)
      if File.exists?(file)
        append_file file, str
      else
        create_file file, str
      end
    end

    # Adds stuff to appconfig.
    def add_config(args)
      if args.is_a? String
        append_file_p 'config/appconfig.yml', reindent(args)
      else
        # Merge...
      end
    end

    # Adds a requirement into the init.rb bootstrapper.
    def add_require(modules)
      str = [modules].flatten.map { |mod| "require \"#{mod}\"\n" }.join('')
      fname = File.join(self.class.source_root, 'init.rb')
      inject_into_file fname, str, :before => /^\s*\nclass/
    end

    # Adds something at the end of the class into the init.rb bootstrapper.
    def add_initializer(str)
      str = reindent(str) + "\n"
      fname = File.join(self.class.source_root, 'init.rb')
      inject_into_file fname, str, :after => "end #class\n\n"
    end

    # Injects something into the main class in the bootstrapper.
    def add_class_def(str)
      str = reindent(str).gsub(/^/, '  ')
      fname = File.join(self.class.source_root, 'init.rb')
      inject_into_file fname, str, :before => "end #class"
    end

    # Adds a gem as a dependency.
    # Example: gem_install 'sinatra-security'
    #
    # Options:
    #     :require => string | true
    #     :git     => string
    #     :version => string (not supported yet)
    #
    # TODO: vendor the requirements as well
    #
    def gem_install(gemname, options={})
      require 'yaml'
      require 'rubygems'

      # Trigger the autoload of this class, as it's needed
      # for YAML::load().
      Gem::Specification

      # Get the gemspec.
      begin
        f = run "gem specification #{gemname}"
        spec = YAML::load(f)
        raise StandardError  if spec === false

      rescue StandardError
        run "gem install #{gemname}"
        retry

      #rescue Gem install failed
        #return ...?
      end

      # Add to the dependencies file.
      add_dependency gemname, options.merge({ :version => spec.version.to_s })

      # Vendor it.
      empty_directory "vendor"
      run "gem unpack #{gemname} -v #{spec.version.to_s} --target=vendor"

      # Add to init.rb
      req = options[:require]
      req = gemname.gsub('-', '/')  if req === true
      add_require req  unless req.nil?
    end

    def add_dependency(gemname, options={})
      create_file 'dependencies' unless File.exists?(File.join(self.class.source_root, 'dependencies'))
      append_file 'dependencies' do
        dep = []
        dep << gemname
        dep << options[:version]   unless options[:version].nil?
        dep << options[:git]       unless options[:git].nil?
        dep.join(' ') + "\n"
      end
    end
  end
end

class Monk < Thor
  include Thor::Actions
  include Nano::Actions

  desc "add", "Adds a package."
  method_option :gem,  :type => :string
  def add(package)
    # Try local
    f = File.join(self.class.recipe_local_path, "#{package}.rb")
    f = File.expand_path(f)
    return apply(f)  if File.exists? (f)

    # Try remote
    begin
      f = "#{self.class.recipe_remote_path}#{package}.rb"
      return apply f
    rescue OpenURI::HTTPError
    end

    # Try gem
    gem_install package, :require => true
  end

  desc "gem", "Adds a gem"
  method_option :git, :type => :string
  method_option :v,   :type => :string
  def gem(gemname, requires=nil)
    opts = {}
    opts[:require]   = requires  unless requires.nil?
    opts[:git]       = options[:git] unless options[:git].nil?
    #opts[:version]  = options[:v]   unless options[:v].nil?

    gem_install(gemname, opts)
  end

private

  def self.recipe_local_path
    File.join(File.dirname(__FILE__), 'recipes')
  end

  def self.recipe_remote_path
    'http://github.com/sinefunc/nanomonk-recipes/tree/master/blob/recipes/'
  end

  def self.source_root
    File.join(File.dirname(__FILE__), '..', '..')
  end
end

Monk.start  if $0 == __FILE__
