module ASpaceCoverage

  require 'asutils'
  require 'tmpdir'
  require 'pp'
  require 'simplecov'

  def self.start(test_name, env = nil)
    SimpleCov.root(ASUtils.find_base_directory)
    SimpleCov.coverage_dir("coverage/#{ENV.fetch('COVERAGE_REPORT_DIR', '')}/#{test_name}")
    SimpleCov.command_name test_name + ":#{Time.now.to_i}:#{$$}"
    SimpleCov.merge_timeout 3600

    puts "Starting coverage reporting for: #{test_name}"

    SimpleCov.start(env) do
      add_group test_name, "."
      add_filter "config/"
      add_filter "build/gems"
      add_filter "common/spec"
      add_filter "backend/spec"
      add_filter "frontend/spec"
      add_filter "public/spec"
      add_filter "indexer/spec"
      add_filter "e2e-tests"
    end
  end
end
