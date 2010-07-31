load './lib/nano/monkactions.rb'
load './lib/nano/nano.rb'

class Monk < Thor
  include Thor::Actions
  include Thor::MonkActions
end

Dir['./lib/thors/*.thor'].each { |fname| load fname }
