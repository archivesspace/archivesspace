# frozen_string_literal: true

# Helper methods for setting browse column preferences in feature specs
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
    record_type = record_type.pluralize if record_type == 'repository'
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

  # Resets multiple browse column preferences to "Default" for the given columns
  #
  # @param record_type [String] The record type
  # @param columns [Hash{Integer => String}] A hash mapping column numbers to their current display values
  # @param scope [Symbol] The preference scope: :global, :repository (default), or :default_repository
  def reset_browse_column_preferences(record_type, columns, scope: :repository)
    default_columns = columns.keys.each_with_object({}) do |column_number, prefs|
      prefs[column_number] = 'Default'
    end

    set_browse_column_preferences(record_type, default_columns, scope: scope)
  end

  # Temporarily sets browse column preferences for the duration of a block,
  # then restores them to "Default" for the same column positions.
  #
  # @param record_type [String] The record type
  # @param columns [Hash{Integer => String}] A hash mapping column numbers to display values
  # @param scope [Symbol] The preference scope: :global, :repository (default), or :default_repository
  #
  # @example Set column 5 to URI for resources
  #   it 'shows the URI column for resources' do
  #     with_browse_column_preferences('resource', { 5 => 'URI' }) do
  #       visit '/resources'
  #       # expectations that rely on column 5 being URI
  #       expect(page).to have_css('th', text: 'URI')
  #     end
  #     # after the block, column 5 is reset back to "Default"
  #   end
  def with_browse_column_preferences(record_type, columns, scope: :repository)
    set_browse_column_preferences(record_type, columns, scope: scope)
    yield
  ensure
    reset_browse_column_preferences(record_type, columns, scope: scope)
  end
end

RSpec.configure do |config|
  config.include BrowseColumnPreferencesHelpers, type: :feature
end
