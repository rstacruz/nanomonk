module Nano
  class AlreadyInstalledError < StandardError; end
  class NoGemError < StandardError; end

  module Actions
    # This module is intended to supplement Thor::Actions with actions that are 
    # useful in extending Monk applications.
    #
    # Usage:
    #   class Monk < Thor
    #     include Thor::Actions
    #     include Nano::Actions
    #   end

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

    # Adds a requirement into the test helpers. 
    #
    # Example:
    #   gem_install 'spawn'
    #   add_test_require 'spawn'
    #
    def add_test_require(modules)
      str = [modules].flatten.map { |mod| "require \"#{mod}\"\n" }.join('')
      fname = File.join(self.class.source_root, 'test', 'test_helper.rb')
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

    # Adds some definitions under class Test::Unit::TestCase.
    #
    # Example:
    #   add_test_helper I(%{
    #     def app
    #       Main.new
    #     end
    #   })
    #
    def add_test_helper(str)
      str = reindent(str).gsub(/^/, '  ')
      fname = File.join(self.class.source_root, 'test', 'test_helper.rb')
      inject_into_file fname, str, :before => "end #class"
    end

    # Adds some statements under Test::Unit::TestCase#setup.
    #
    # Example:
    #   add_test_setup I(%{
    #     # Remove this if you don't want a fresh database everytime.
    #     Ohm.flush
    #   })
    #
    def add_test_setup(str)
      str = reindent(str).gsub(/^/, '    ')
      fname = File.join(self.class.source_root, 'test', 'test_helper.rb')
      inject_into_file fname, str, :before => "  end #setup"
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
    end

    # Works like append_file, except creates files if they aren't found.
    #
    def append_file_p(file, str)
      File.exists?(file) ? append_file(file, str) : create_file(file, str)
    end

    # Adds a gem to the dependency file.
    # (This will almost never need to be called.)
    #
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
    #
    def reindent(str)
      str = str[1..-1]  if str[0] == "\n"       # Remove first newline
      str.gsub!(/^#{str.match(/^\s*/)[0]}/, '') # Unindent
      str += "\n"  unless str[-1] == "\n"       # Ensure last newline
      str
    end

    # Installs a given package.
    # This differs from #gem_install by trying recipes first, and
    # displaying caveats after.
    #
    # Raises:
    #   Nano::AlreadyInstalledError
    #   Nano::NoGemError
    #
    def install_package(package, options={})
      unless options[:gem]
        # Try locals
        f = self.class.recipe_path("#{package}.rb")
        return apply(f)  if File.exists?(f)

        # Try remotes one by one
        recipe_remotes.each do |remote|
          begin
            url = remote[:url] % { :package => package }
            return apply(url)
          rescue OpenURI::HTTPError; end
        end
      end

      # Try installing the gem.
      req_name = package.gsub('-', '/')
      gem_install package
      add_require req_name

      caveats I(%{
        The gem `#{package}` has been installed.
        init.rb has been auto-updated with `require "#{req_name}"`.
      })
    end
    
  private

    # Returns the remote path for the recipe for the given package.
    # Example:
    #
    #   p self.recipe_remotes
    #   # [ { :name => 'custom', :url => 'http://yyy/%{package}.rb' },
    #   #   { :name => 'default', :url => 'http://xxx/%{package}.rb' }
    #   # ]
    #
    def recipe_remotes
      fname = File.join(root_path, 'config', 'nano_sources.list')
      File.open(fname) do |f|
        f.read.split("\n").inject([]) do |a, line|
          unless line.match(/^\s*#/) or line.count(' ') == 0
            parts = line.partition(" ")
            a << { :name => parts[0], :url => parts[2] }
          end
          a
        end
      end
    end

    # Returns the Gem::Specification for a certain gem.
    # Returns nil if the gem is not available.
    #
    def get_gemspec(gemname)
      # Trigger the autoload of this class, as it's needed
      # for YAML::load().
      Gem::Specification
      specs = `gem specification #{gemname} 2>&1`
      return nil  if $?.to_i > 0

      require 'yaml'
      YAML::load(specs) || nil
    end

    # Install the dependencies for the given gem.
    # gem is a Gem::Specification.
    #
    def dependize(gem)
      return if gem.nil?
      gem = get_gemspec(gem)  if gem.is_a? String

      # Add to deps
      add_dependency gem.name, options.merge({ :version => gem.version.to_s })

      # Then vendorize it
      gem_dir = File.join(root_path, 'vendor', "#{gem.name}-#{gem.version.to_s}")
      unless File.directory?(gem_dir)
        run "gem unpack #{gem.name} -v #{gem.version.to_s} --target=vendor"
        remove_dir File.join(gem_dir, 'test')
      end

      # Recurse to dependencies (ignore dev/test gems)
      gem.dependencies.each do |dep|
        next  if dep.type != :runtime
        dependize dep.name
      end
    end
  end
end
