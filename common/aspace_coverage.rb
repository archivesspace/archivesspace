module ASpaceCoverage

  require 'tmpdir'
  require 'pp'
  require 'simplecov'

  def self.start(test_name, env = nil)
    SimpleCov.root(File.join(File.dirname(__FILE__), ".."))
    SimpleCov.coverage_dir("coverage")
    SimpleCov.command_name test_name + ":#{Time.now.to_i}:#{$$}"
    SimpleCov.merge_timeout 3600

    SimpleCov.start(env) do
      add_filter "config/"
      add_filter "build/gems"
    end
  end
end
