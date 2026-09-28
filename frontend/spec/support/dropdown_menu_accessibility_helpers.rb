# frozen_string_literal: true

# Helpers for Bootstrap 4 `data-toggle="dropdown"` menu-button toggles only.
#
# Contract (menu trigger, not combobox / disclosure / custom panels):
# - aria-haspopup="true"
# - aria-expanded="false" initially, then true after open, false after close
#   (Bootstrap dropdown plugin updates expanded at runtime for standard toggles)
#
# TODO: fix UI then extend coverage for other disclosure patterns, for example:
# - Linker combobox wrappers (role="combobox") and token-input listboxes
# - Advanced search panel switcher (custom disclosure, not a Bootstrap menu)
# - Merge/transfer/event toolbars where custom JS manages aria-expanded
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
