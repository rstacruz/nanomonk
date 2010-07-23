module Nano
  class AlreadyInstalledError < StandardError; end
  class NoGemError < StandardError; end

  module Actions
    # Unindents text. Good for heredocs and such.
    #
    # Example:
    #   caveat I(%{
    #     Running:
    #         type `rake minify` to run the process.
    #   })
    #
    def I(str)
      reindent(str)
    end

    # Queries if a gem is installed in the dependencies file.
    #
    # Example:
    #   if installed? 'less' 
    #     caveat "PROTIP: Install less for a good time!"
    #   end
    #   
    def installed?(gem)
      fname = 'dependencies'
      return false  unless File.exists?(fname)
      
      # Fail if not found in the deps file
      deps = File.open(fname) { |f| f.read }
      not deps.match(/^#{gem}/).nil?
    end

    # Add caveats to be shown at the end of the process.
    #
    # Example:
    #   caveats %{
    #     Ohm has been installed. Please make sure you have Redis
    #     installed, otherwise results will be catastrophic.
    #   }
    #
    def caveats(str)
      @caveats ||= []
      @caveats << reindent(str)
    end

    # Adds directives to the app config file. Accepts strings or hashes.
    #
    # Example:
    #   add_config { 's3': { 'key': '00xx' } }
    #
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
    #
    # Example:
    #   gem_install 'redcloth'
    #   add_require 'RedCloth'
    #
    def add_require(modules)
      str = [modules].flatten.map { |mod| "require \"#{mod}\"\n" }.join('')
      fname = File.join(self.class.source_root, 'init.rb')
      inject_into_file fname, str, :before => /^\s*\nclass/
    end

    def add_test_require(modules)
      str = [modules].flatten.map { |mod| "require \"#{mod}\"\n" }.join('')
      fname = File.join(self.class.source_root, 'test', 'test_helpers.rb')
      inject_into_file fname, str, :before => /^\s*\nclass/
    end

    # Adds something at the end of the class into the init.rb bootstrapper.
    # The given string will be added to the end of the class definition.
    # 
    # Example:
    #   add_initializer I(%{
    #     # Connect to the database.
    #     Ohm.connect(...)
    #   })
    #
    def add_initializer(str)
      str = reindent(str) + "\n"
      fname = File.join(self.class.source_root, 'init.rb')
      inject_into_file fname, str, :after => "end #class\n\n"
    end

    # Injects something into the main class in the bootstrapper.
    #
    # Example:
    #   add_class_def I(%{
    #     register Sinatra::I18n
    #   })
    #
    def add_class_def(str)
      str = reindent(str).gsub(/^/, '  ')
      fname = File.join(self.class.source_root, 'init.rb')
      inject_into_file fname, str, :before => "end #class"
    end

    def add_test_helper(str)
      str = reindent(str).gsub(/^/, '  ')
      fname = File.join(self.class.source_root, 'test', 'test_helper.rb')
      inject_into_file fname, str, :before => "end #class"
    end

    def add_test_setup(str)
      str = reindent(str).gsub(/^/, '    ')
      fname = File.join(self.class.source_root, 'test', 'test_helper.rb')
      inject_into_file fname, str, :before => "end #setup"
    end

    # Adds a gem as a dependency.
    # Example: gem_install 'sinatra-security'
    #
    # Options:
    #     :require => string | true
    #     :git     => string
    #     :version => string (not supported yet)
    #
    def gem_install(gemname, options={})
      raise Nano::AlreadyInstalledError  if installed?(gemname)

      # Get the gemspec; install it if needed.
      spec = get_gemspec(gemname)
      if spec.nil?
        run "gem install #{gemname}"
        raise Nano::NoGemError  if $?.to_i > 0
        spec = get_gemspec(gemname)
      end

      # Add it (and it's dependencies) to the deps file,
      # and unpack the gems to vendor/.
      empty_directory "vendor"
      dependize(spec)

      # Add to init.rb. Infer the require name from the gem name
      # (ohm-contrib => 'ohm/contrib')
      req = options[:require]
      req = gemname.gsub('-', '/')  if req === true
      add_require req  unless req.nil?
    end

    # Works like append_file, except creates files if they aren't found.
    def append_file_p(file, str)
      File.exists?(file) ? append_file(file, str) : create_file(file, str)
    end

    # Adds a gem to the dependency file.
    # (This will almost never need to be called.)
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

    # Reindents a string. Good for heredoc strings and such.
    def reindent(str)
      str = str[1..-1]  if str[0] == "\n" # Remove first newline
      str.gsub!(/^#{str.match(/^\s*/)[0]}/, '') # Unindent
      str += "\n"  unless str[-1] == "\n" # Ensure last newline
      str
    end

  private

    # Returns the Gem::Specification for a certain gem.
    # Returns nil if the gem is not available.
    def get_gemspec(gemname)
      # Trigger the autoload of this class, as it's needed
      # for YAML::load().
      Gem::Specification
      specs = `gem specification #{gemname} 2>&1`
      return nil  if $?.to_i > 0

      require 'yaml'
      YAML::load(specs) || nil
    end

    # Gem::Specification
    def dependize(gem)
      return if gem.nil?
      add_dependency gem.name, options.merge({ :version => gem.version.to_s })
      run "gem unpack #{gem.name} -v #{gem.version.to_s} --target=vendor"

      gem.dependencies.each do |dep|
        next  if dep.type != :runtime
        spec = get_gemspec(dep.name)
        dependize spec
      end
    end
  end
end
