module Nano
  AlreadyInstalledError = Class.new(StandardError)
  NoGemError            = Class.new(StandardError)

  autoload :Actions, File.join(File.dirname(__FILE__), 'nano', 'actions')
end
