class Monk < Thor
  desc "test [type]", "Run all tests"
  def test(type=nil)
    verify_config(:test)

    $:.unshift File.join(File.dirname(__FILE__), "..", "..", "test")

    spec = %W{test #{type} ** *_test.rb'}.reject(&:empty?).join('/')
    Dir[spec].each { |file| load file  unless file =~ /^-/ }
  end
end
