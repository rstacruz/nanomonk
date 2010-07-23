require 'thor'
require './nano'

class Monk < Thor
  include Thor::Actions
  include Nano::Actions

  desc "add", "Adds a package."
  def add(package)
    begin
      # Try local
      f = File.join(self.class.recipe_local_path, "#{package}.rb")
      f = File.expand_path(f)
      return apply(f)  if File.exists? (f)

      # Try remote
      begin
        return apply("#{self.class.recipe_remote_path}#{package}.rb")
      rescue OpenURI::HTTPError
      end

      # Try gem
      gem_install package, :require => true

    rescue Nano::AlreadyInstalledError
      puts "This gem is already installed."

    rescue Nano::NoGemError
      puts "No such gem/package."
    end
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
