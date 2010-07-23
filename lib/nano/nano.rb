module Nano
  class AlreadyInstalledError < StandardError; end
  class NoGemError < StandardError; end

  module Actions
    def I(str)
      reindent(str)
    end

    # Queries if a gem is installed in the dependencies file.
    def installed?(gem)
      fname = 'dependencies'
      return false  unless File.exists?(fname)
      
      # Fail if not found in the deps file
      deps = File.open(fname) { |f| f.read }
      not deps.match(/^#{gem}/).nil?
    end

    # Reindents a string. Good for heredoc strings and such.
    def reindent(str)
      str = str[1..-1]  if str[0] == "\n" # Remove first newline
      str.gsub!(/^#{str.match(/^\s*/)[0]}/, '') # Unindent
      str += "\n"  unless str[-1] == "\n" # Ensure last newline
      str
    end

    # Works like append_file, except creates files if they aren't found.
    def append_file_p(file, str)
      File.exists?(file) ? append_file(file, str) : create_file(file, str)
    end

    # Add caveats to be shown at the end of the process.
    def caveats(str)
      @caveats ||= []
      @caveats << str
    end

    # Adds directives to the app config file. Accepts strings or hashes.
    def add_config(args)
      # Strings: append at EOF.
      if args.is_a? String
        append_file_p 'config/appconfig.yml', reindent(args)

      # Hash: Merge the hash into the current app config.
      elsif args.is_a? Hash
        require 'yaml'
        fname = 'config/appconfig.yml'
        
        config = {}
        config = YAML::load(fname)  if File.exists?(fname)
        config = config.merge(args)
        File.open(fname, 'w') { |f| f << YAML::dump(config) }
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

      raise Nano::AlreadyInstalledError  if installed?(gemname)

      # Trigger the autoload of this class, as it's needed
      # for YAML::load().
      Gem::Specification

      # Get the gemspec.
      begin
        f = run "gem specification #{gemname}"
        spec = YAML::load(f)
        raise StandardError  if $?.to_i > 0

      rescue StandardError
        run "gem install #{gemname}"
        raise Nano::NoGemError  if $?.to_i > 0
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

    # Adds a gem to the dependency file.
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

