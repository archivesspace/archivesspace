module ASpaceHelpers
  include Capybara::DSL
  include TestUtils::SpecBatchCreate

  # Creates `count` published archival objects under `parent` (or at the top
  # level of `resource`) with a single batch import request.  See
  # TestUtils::SpecBatchCreate#batch_create_tree_children.
  def batch_create_archival_objects(count, resource:, parent: nil, **values, &block)
    batch_create_tree_children(:archival_object, count, root_key: :resource, root: resource, parent: parent,
                               publish: true, **values, &block)
  end

  # Bootstrap ignores show() and hide() while a transition is still running.
  def wait_for_animations
    page.document.synchronize do
      running = page.evaluate_script(<<~JS)
        (window.jQuery ? jQuery.timers.length : 0) +
          document.getAnimations().filter(a => a.effect.getTiming().iterations !== Infinity).length
      JS
      raise Capybara::ExpectationNotMet, "#{running} animations running" unless running.zero?
    end
  end
end
