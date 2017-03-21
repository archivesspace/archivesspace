require 'rspec'

class ParallelFormatterOut < RSpec::Core::Formatters::DocumentationFormatter
  RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished, :example_passed, :example_pending, :example_failed, :dump_failures


  def example_group_started(notification)
    output.puts if @group_level == 0
    output.puts "#{thread_id} #{notification.group.description.strip}"

    @group_level += 1
  end



  def example_passed(passed)
    output.puts passed_output(passed.example)
  end



  def dump_failures(notification)
    return if notification.failure_notifications.empty?
    output.puts thread_id + notification.fully_formatted_failed_examples
  end


  def dump_summary(summary)
    output.puts summary.fully_formatted.strip.split("\n").map{|l| "#{thread_id} " + l }.join("\n")
  end



  private

  def passed_output(example)
    thread_id + " " + RSpec::Core::Formatters::ConsoleCodes.wrap("#{example.metadata[:example_group][:full_description].strip}: #{example.description.strip}", :success)
  end

  def failure_output(example)
    thread_id + " " + RSpec::Core::Formatters::ConsoleCodes.wrap("#{example.metadata[:example_group][:full_description].strip}: #{example.description.strip} " "(FAILED - #{next_failure_index})",
                            :failure)
  end

  def thread_id
    id = (ENV['TEST_ENV_NUMBER'].empty?) ? 1 : ENV['TEST_ENV_NUMBER'] # defaults to 1
    # "[#{Thread.current.object_id}]"
    "[#{id}]"
  end


end
