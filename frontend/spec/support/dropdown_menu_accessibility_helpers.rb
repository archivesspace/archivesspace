# frozen_string_literal: true

module DropdownMenuAccessibilityHelpers
  # @param selector [String] Capybara selector for the menu toggle control
  def expect_dropdown_menu_toggle(selector)
    button = find(selector)

    expect(button[:'aria-expanded']).to eq('false'),
                                        "expected #{selector} to start with aria-expanded=\"false\""

    expect(button[:'aria-haspopup']).to eq('true'),
                                        "expected #{selector} to expose aria-haspopup=\"true\""

    button.click

    expect(find(selector)[:'aria-expanded']).to eq('true'),
                                                "expected #{selector} aria-expanded to become \"true\" after open"

    button.click

    expect(find(selector)[:'aria-expanded']).to eq('false'),
                                                "expected #{selector} aria-expanded to become \"false\" after close"
  end
end
