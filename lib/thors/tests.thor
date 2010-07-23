class Monk < Thor
  desc "test", "Run all tests"
  def test
    verify_config(:test)

    $:.unshift File.join(File.dirname(__FILE__), "..", "..", "test")

    Dir['test/**/*_test.rb'].each do |file|
      load file unless file =~ /^-/
    end
  end

  desc "test_unit", "Run all unit tests"
  def test_unit
    verify_config(:test)

    $:.unshift File.join(File.dirname(__FILE__), "..", "..", "test")

    Dir['test/unit/**/*_test.rb'].each do |file|
      load file unless file =~ /^-/
    end
  end

  desc "test_routes", "Run all route tests"
  def test_routes
    verify_config(:test)

    $:.unshift File.join(File.dirname(__FILE__), "..", "..", "test")

    Dir['test/routes/**/*_test.rb'].each do |file|
      load file unless file =~ /^-/
    end
  end

  desc "stories", "Run user stories."
  method_option :pdf, :type => :boolean
  def stories
    $:.unshift(Dir.pwd, "test")

    ARGV << "-r"
    ARGV << (options[:pdf] ? "stories-pdf" : "stories")
    ARGV.delete("--pdf")

    Dir["test/stories/*_test.rb"].each do |file|
      load file
    end
  end
end
