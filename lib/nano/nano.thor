require 'thor'
require File.join(File.dirname(__FILE__), 'nano')

class Monk < Thor
  include Thor::Actions
  include Nano::Actions

  desc "install", "Installs a package."
  method_option :gem, :type => :boolean
  def install(package)
    begin
      install_package package, options

      unless @caveats.nil?
        puts "\n" + [@caveats].join("\n\n")
      end
      
    rescue Nano::AlreadyInstalledError
      puts "This gem is already installed."

    rescue Nano::NoGemError
      puts "No such gem/package."
    end
  end

private
  def install_package(package, options)
    unless options[:gem]
      # Try local and remote
      f = self.class.recipe_path("#{package}.rb")
      f = self.class.recipe_remote(package) unless File.exists?(f)

      begin
        apply(f)
      rescue OpenURI::HTTPError
        nil
      end
    end

    # Try gem
    gem_install package
    caveats I(%{
      The gem `#{package}` has been installed.
      Don't forget to add it the `require "#{package.gsub('-','/')}"` yourself!
    })
  end
  
  def self.recipe_path(*args)
    fname = File.join(File.dirname(__FILE__), 'recipes', args)
    File.expand_path(fname)
  end

  def self.recipe_remote(package)
    "http://github.com/rstacruz/nanomonk-recipes/raw/master/recipes/#{package}.rb"
  end

  def self.source_root
    File.join(File.dirname(__FILE__), '..', '..')
  end
end

Monk.start  if $0 == __FILE__
