module ASpaceCoverage

  require 'asutils'
  require 'tmpdir'
  require 'pp'
  require 'simplecov'

  def self.start(test_name, env = nil)

    SimpleCov.root(ASUtils.find_base_directory)
    SimpleCov.coverage_dir("coverage")
    SimpleCov.command_name test_name + ":#{Time.now.to_i}:#{$$}"
    SimpleCov.merge_timeout 3600

    SimpleCov.start(env) do
      add_filter "config/"
      add_filter "build/gems"
      add_filter "common/spec"
      add_filter "backend/spec"
      add_filter "backend/tests"
      add_filter "frontend/spec"
      add_filter "selenium"
    end
  end
end
