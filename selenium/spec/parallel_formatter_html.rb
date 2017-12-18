require 'rspec'
require 'fileutils'
require 'tmpdir'

RSpec::Support.require_rspec_core "formatters/console_codes"


class ParallelFormatterHTML < RSpec::Core::Formatters::HtmlFormatter

  RSpec::Core::Formatters.register self, :start, :example_group_started, :start_dump, :example_started, :example_passed, :example_failed, :example_pending, :dump_summary


  def initialize(param=nil)
    # output_dir = ENV['OUTPUT_DIR'] || File.join(File.dirname(__FILE__), 'log')
    output_dir = ENV['SELENIUM_LOG_DIR'] || File.join( Dir.tmpdir, 'log')  
    FileUtils.mkpath(output_dir) unless File.directory?(output_dir)
    raise "Invalid output directory: #{output_dir}" unless File.directory?(output_dir)

    id = (ENV['TEST_ENV_NUMBER'].empty?) ? 1 : ENV['TEST_ENV_NUMBER'] # defaults to 1
    output_file = File.join(output_dir, "result#{id}.html")
    opened_file = File.open(output_file, 'w+')
    super(opened_file)

  end
end
