module ASpaceCoverage
  require 'asutils'
  require 'tmpdir'
  require 'pp'

  def self.start(group_name, env = nil)
    require 'simplecov'
    require 'fileutils'

    SimpleCov.root(ASUtils.find_base_directory)

    # Always save coverage reports to the data directory
    base_dir = ENV.fetch('APPCONFIG_DATA_DIR', File.join(Dir.home, 'ArchivesSpace'))
    coverage_dir = File.join(base_dir, 'coverage', ENV.fetch('COVERAGE_REPORT_DIR', ''), group_name)
    SimpleCov.coverage_dir(coverage_dir)

    SimpleCov.command_name group_name + ":#{Time.now.to_i}:#{$$}"
    SimpleCov.merge_timeout 3600

    puts "Starting coverage reporting for: #{group_name}"
    puts "Coverage directory: #{coverage_dir}"

    SimpleCov.start(env) do
      add_group group_name, "."
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
