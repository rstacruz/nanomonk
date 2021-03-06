require 'thor'

class Monk < Thor
  include Thor::Actions
  include Nano::MonkActions
  include Nano::Actions

  desc "install", "Installs a package."
  method_option :gem,    :type => :boolean
  method_option :test,   :type => :boolean
  method_option :git,    :type => :string
  method_option :github, :type => :string

  def install(*packages)
    opts = options.inject({}) { |hash, (k, v)| hash[k.to_sym] = v; hash }

    # In case it's called with --github=user/repo
    if opts[:github]
      opts[:git] = "git://github.com/#{opts[:github]}.git"
      opts[:github] = nil
    end

    packages.each do |package|
      begin
        install_package package, opts
        
      rescue Nano::AlreadyInstalledError
        puts "This gem is already installed."

      rescue Nano::NoGemError
        puts "No such gem/package."
      end
    end

    unless @caveats.nil?
      puts "\n" + [@caveats].join("\n\n")
    end

    unless @notes.nil?
      outputs = @notes.inject([]) do |a, (section, texts)|
        a << section.capitalize + "\n" + ("=" * section.size)
        a |= texts
      end

      puts "\n" + outputs.join("\n\n") + "\n"
    end
  end

private
  # Returns the local path for recipes. Doing an #install_package will check 
  # this directory first for a recipe file; if it doesn't find it here, it moves 
  # onto checking it remotely. This folder is optional and doesn't need to exist.
  #
  def self.recipe_path(*args)
    fname = File.join(File.dirname(__FILE__), 'recipes', args)
    File.expand_path(fname)
  end

  def self.source_root
    File.join(File.dirname(__FILE__), '..', '..')
  end
end

Monk.start  if $0 == __FILE__
