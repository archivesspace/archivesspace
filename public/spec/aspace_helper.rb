module ASpaceHelpers
  include Capybara::DSL
  include TestUtils::SpecBatchCreate

  def wait_for_jquery
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 1
      loop until finished_all_ajax_requests?
    end
  end

  # Creates `count` published archival objects under `parent` (or at the top
  # level of `resource`) with a single batch import request.  See
  # TestUtils::SpecBatchCreate#batch_create_tree_children.
  def batch_create_archival_objects(count, resource:, parent: nil, **values, &block)
    batch_create_tree_children(:archival_object, count, root_key: :resource, root: resource, parent: parent,
                               publish: true, **values, &block)
  end

  def finished_all_ajax_requests?
    page.evaluate_script("typeof window.jQuery != 'undefined'") &&
      page.evaluate_script('window.jQuery !== undefined') &&
      page.evaluate_script('jQuery.active !== undefined') &&
      page.evaluate_script('jQuery.active')&.zero?
  rescue Selenium::WebDriver::Error::JavascriptError
    false
  end
end
