# frozen_string_literal: true

# Helper methods for building sort expectations in feature specs.
module SortExpectationHelpers
  # Derives the ascending and descending sort expectations where URI numeric IDs
  # are sorted as strings, e.g. '/resources/11' < '/resources/9' because '1' < '9'.
  #
  # @param records [Array<Object>] the records to sort by URI
  # @param value_proc [#call] a callable that maps a record to the expected
  #   value in the primary column (e.g. title, id, repo_code)
  # @return [Hash{Symbol=>Array}] { asc: [...], desc: [...] }
  def uri_id_as_string_sort_expectations(records, value_proc)
    uri_asc = records.sort_by(&:uri).map { |record| value_proc.call(record) }
    uri_desc = uri_asc.reverse

    { asc: uri_asc, desc: uri_desc }
  end
end

RSpec.configure do |config|
  config.include SortExpectationHelpers, type: :feature
end
