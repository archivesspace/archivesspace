# frozen_string_literal: true

# Shared context for setting up feature specs that use the
# 'sortable results table' shared examples.
#
# Expected lets provided by the including context:
# - now [Integer] Timestamp used for uniqueness in record creation and filtering
# - record_type [String] The record type used for browse column preferences
#   (e.g. 'accession', 'resource', 'multi') when browse columns are configured.
# - browse_path [String] The path to visit for the browse view (e.g. '/accessions').
#   Used by the default implementation of go_to_results_table.
# - record_1 [Record] The first test record to create (called during setup_records)
# - record_2 [Record] The second test record to create (called during setup_records)
# - additional_browse_columns [Hash{Integer => String}] A hash mapping column numbers to
#   display values for the sortable columns. When omitted, preferences are not
#   changed by this context.
#
# Optional lets:
# - browse_column_scope [Symbol] The preference scope: :global, :repository (default),
#   or :default_repository.
# - filter_results [Boolean] Whether to filter the results to include only the necessary
#   records in the results set (using the 'now' timestamp as the filter text).
# - use_repo_for_sorting_context [Boolean] Defaults to true. Set to false for
#   global listings that are not scoped to a repo (e.g. for repositories).
#
# Methods that specs can override:
# - go_to_results_table: Override for modal-based results or custom navigation flows.
RSpec.shared_context 'sortable results table setup' do
  include_context 'filter search results by text'

  let(:repo) { create(:repo, repo_code: "#{record_type}_results_sorting_#{now}") }
  let(:pref_type_label) { record_type == 'repository' ? record_type.pluralize : record_type }
  let(:browse_column_scope) { :repository }

  before do
    set_repo(repo) if use_repo_for_sorting_context?
    setup_records
    run_index_round
    login_admin
    select_repository(repo) if use_repo_for_sorting_context?
    setup_additional_columns
    go_to_results_table
    filter_results_for_comparison
  end

  after do
    reset_columns
  end

  def use_repo_for_sorting_context?
    respond_to?(:use_repo_for_sorting_context) ? !!use_repo_for_sorting_context : true
  end

  def setup_records
    record_1 if respond_to?(:record_1)
    record_2 if respond_to?(:record_2)
  end

  def setup_additional_columns
    return unless respond_to?(:additional_browse_columns) && additional_browse_columns

    set_browse_column_preferences(pref_type_label, additional_browse_columns, scope: browse_column_scope)
  end

  # Override this method for modal-based results or other custom flows
  def go_to_results_table
    visit browse_path if respond_to?(:browse_path)
    expect(page).to have_css('#tabledSearchResults')
  end

  def filter_results_for_comparison
    return unless respond_to?(:filter_results) && filter_results

    filter_search_results_by_text(now.to_s)
  end

  def reset_columns
    return unless respond_to?(:additional_browse_columns) && additional_browse_columns

    reset_browse_column_preferences(pref_type_label, additional_browse_columns, scope: browse_column_scope)
  end
end
