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

    selections = columns.each_with_object({}) do |(column_number, column_value), prefs|
      prefs["#{record_type}_browse_column_#{column_number}"] = column_value
    end

    set_preference_selections(selections, scope: scope)
  end

  # Sets any preference <select>s on the preferences page for the given scope
  #
  # @param selections [Hash{String => String}] A hash mapping preference keys
  #   (e.g. 'accession_sort_column') to the option display value to select
  # @param scope [Symbol] The preference scope: :global, :repository (default), or :default_repository
  def set_preference_selections(selections, scope: :repository)
    selector = PREFERENCE_SCOPE_SELECTORS.fetch(scope) do
      raise ArgumentError, "Invalid scope: #{scope.inspect}. Must be one of: #{PREFERENCE_SCOPE_SELECTORS.keys.join(', ')}"
    end

    find('#user-menu-dropdown').click
    wait_for_next_page { find(selector, visible: true).click }

    selections.each do |preference_key, option_label|
      select option_label, from: "preference_defaults__#{preference_key}_"
    end

    wait_for_next_page { click_on 'Save Preferences' }
    expect(page).to have_css('.alert-success', text: 'Preferences updated')
  end

  # Marks the current page, so a check after the block can't match it instead of the page the block opens
  def wait_for_next_page
    page.execute_script("document.body.dataset.previousPage = 'true'")
    yield
    expect(page).to have_no_css('body[data-previous-page]')
  end

  # Runs the reset after the block; when the block fails, a failing reset is only printed so it can't hide that error
  def run_then_reset(reset)
    yield
  rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
    begin
      reset.call
    rescue StandardError, RSpec::Expectations::ExpectationNotMetError => reset_error
      warn "Resetting preferences after a failure also failed: #{reset_error.message}"
    end
    raise e
  else
    reset.call
  end

  # Temporarily sets preference <select>s for the duration of a block, then
  # restores them to "Default".
  #
  # @param selections [Hash{String => String}] See #set_preference_selections
  # @param scope [Symbol] The preference scope: :global, :repository (default), or :default_repository
  def with_preference_selections(selections, scope: :repository)
    run_then_reset(-> { set_preference_selections(selections.transform_values { 'Default' }, scope: scope) }) do
      set_preference_selections(selections, scope: scope)
      yield
    end
  end

  # Sets the Action Buttons (View/Edit) Position preference for a record type
  #
  # @param record_type [String] The record type (e.g. 'accession', 'multi', 'top_container_mgmt')
  # @param position_label [String] 'Left', 'Right', or 'Default'
  # @param scope [Symbol] The preference scope: :global, :repository (default), or :default_repository
  def set_actions_column_position(record_type, position_label, scope: :repository)
    record_type = record_type.pluralize if record_type == 'repository'
    set_preference_selections({ "#{record_type}_actions_column_position" => position_label }, scope: scope)
  end

  # Temporarily sets the Action Buttons (View/Edit) Position preference for a
  # record type for the duration of a block, then restores it to "Default".
  def with_actions_column_position(record_type, position_label, scope: :repository, &block)
    record_type = record_type.pluralize if record_type == 'repository'
    with_preference_selections({ "#{record_type}_actions_column_position" => position_label }, scope: scope, &block)
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
    run_then_reset(-> { reset_browse_column_preferences(record_type, columns, scope: scope) }) do
      set_browse_column_preferences(record_type, columns, scope: scope)
      yield
    end
  end
end

RSpec.configure do |config|
  config.include BrowseColumnPreferencesHelpers, type: :feature
end
