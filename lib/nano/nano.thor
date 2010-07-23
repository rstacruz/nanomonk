require 'thor'
require File.join(File.dirname(__FILE__), 'nano')

class Monk < Thor
  include Thor::Actions
  include Nano::Actions

  desc "install", "Installs a package."
  method_option :gem, :type => :boolean
  def install(package)
    catch :done do
      begin
        unless options[:gem]
          # Try local
          f = File.join(self.class.recipe_local_path, "#{package}.rb")
          f = File.expand_path(f)
          if File.exists?(f)
            apply(f)
            throw :done
          end

          # Try remote
          begin
            apply("#{self.class.recipe_remote_path}#{package}.rb")
            throw :done
          rescue OpenURI::HTTPError
          end
        end

        # Try gem
        gem_install package
        caveats I(%{
          The gem `#{package}` has been installed.
          Don't forget to add it the `require "#{package.gsub('-','/')}"` yourself!
        })
        throw :done

      rescue Nano::AlreadyInstalledError
        puts "This gem is already installed."
        return

      rescue Nano::NoGemError
        puts "No such gem/package."
        return
      end
    end

    unless @caveats.nil?
      puts "\n" + [@caveats].join("\n\n")
    end
  end

private

  def self.recipe_local_path
    File.join(File.dirname(__FILE__), 'recipes')
  end

  def self.recipe_remote_path
    'http://github.com/rstacruz/nanomonk-recipes/raw/master/recipes/'
  end

  def self.source_root
    File.join(File.dirname(__FILE__), '..', '..')
  end
end

Monk.start  if $0 == __FILE__
