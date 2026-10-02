# frozen_string_literal: true

module FocusAssertionHelpers
  # @param target [Capybara::Node::Element, String] a located node or CSS selector
  def expect_focus_on(target)
    element = target.is_a?(Capybara::Node::Element) ? target : find(target)

    focused = page.evaluate_script(
      'return arguments[0] === document.activeElement',
      element.native
    )

    expect(focused).to be(true), "expected keyboard focus on #{element.path}"
  end
end

RSpec.configure do |config|
  config.include FocusAssertionHelpers, type: :feature
end
