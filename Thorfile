class Monk < Thor
  include Thor::Actions

private
  def root_path(*args)
    File.expand_path(File.join(File.dirname(__FILE__), args))
  end
end

Dir['lib/thors/*.thor'].each { |f| load f }
load 'lib/nano/nano.thor'

Monk.start  if $0 == __FILE__
