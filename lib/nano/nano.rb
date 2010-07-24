module Nano
  class AlreadyInstalledError < StandardError; end
  class NoGemError < StandardError; end

  autoload :Actions, File.join(File.dirname(__FILE__), 'nano', 'actions')
end
