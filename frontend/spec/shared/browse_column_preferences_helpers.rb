# frozen_string_literal: true

# Helper methods for setting browse column preferences in feature specs,
# auto-loaded by rails_helper.rb.
#
# Example: set a single browse column preference with the default (repository) scope
#
#   set_browse_column_preference('resource', 6, 'URI')
#
# Example: set multiple browse column preferences with global scope
#
#   set_browse_column_preferences(
#     'event',
#     {
#       3 => 'Date',
#       4 => 'Type',
#       5 => 'URI'
#     },
#     scope: :global
#   )
module BrowseColumnPreferencesHelpers
  include Capybara::DSL

  PREFERENCE_SCOPE_SELECTORS = {
    global: 'a[href*="preferences/0/edit?global=true"]',
    repository: 'a[href*="preferences/0/edit"]:not([href*="?"])',
    default_repository: 'a[href*="preferences/0/edit?repo=true"]'
  }.freeze

  # Sets multiple browse column preferences for a given record type and scope
  #
  # @param record_type [String] The record type
  # @param columns [Hash{Integer => String}] A hash mapping column numbers to display values
  # @param scope [Symbol] The preference scope: :global, :repository (default), or :default_repository
  def set_browse_column_preferences(record_type, columns, scope: :repository)
    selector = PREFERENCE_SCOPE_SELECTORS.fetch(scope) do
      raise ArgumentError, "Invalid scope: #{scope.inspect}. Must be one of: #{PREFERENCE_SCOPE_SELECTORS.keys.join(', ')}"
    end

    find('#user-menu-dropdown').click
    find(selector, visible: true).click

    columns.each do |column_number, column_value|
      select column_value, from: "preference_defaults__#{record_type}_browse_column_#{column_number}_"
    end

    click_on 'Save Preferences'
  end

  # Sets a single browse column preference for a given record type and scope
  #
  # @param record_type [String] The record type
  # @param column_number [Integer] The column number
  # @param column_value [String] The option display value to select
  # @param scope [Symbol] The preference scope: :global, :repository (default), or :default_repository
  def set_browse_column_preference(record_type, column_number, column_value, scope: :repository)
    set_browse_column_preferences(record_type, { column_number => column_value }, scope: scope)
  end
end

# Auto-include these helpers in all feature specs
RSpec.configure do |config|
  config.include BrowseColumnPreferencesHelpers, type: :feature
end
