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

      unless @notes.nil?
        outputs = []
        @notes.each do |section, text|
          fname = "README.#{section}.md"
          text  = text.join("\n\n")
          outputs << fname + "\n" + ("=" * fname.size)
          outputs << text
          append_file_p fname, text
        end

        puts "\n" + outputs.join("\n\n") + "\n"
      end
      
    rescue Nano::AlreadyInstalledError
      puts "This gem is already installed."

    rescue Nano::NoGemError
      puts "No such gem/package."
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
