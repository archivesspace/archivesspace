class SolrResults
  include RecordHelper

  attr_reader :raw, :facets, :records

  def initialize(solr_results, search_opts = {}, full = false)
    @raw = solr_results
    @records = parse_records(full)
    @search_opts = search_opts
  end

  def empty?
    @raw['results'].blank? || @raw['results'].empty?
  end

  def first
    @records.first
  end

  # while this is available it cannot be private Ruby 2.5+
  def [](k)
    # $stderr.puts "FIXME stop direct access to the results json blob ([]): #{caller.first}"
    raw[k]
  end

  private

  def parse_records(full)
    Array(@raw['results']).map {|result| parse_record(result, full) }
  end

  def parse_record(result, full)
    record = record_for_type(result, full)
    record.criteria = @search_opts
    record.apply_highlighting(find_highlighting(result['id']))

    record
  end

  def find_highlighting(result_id)
    return {} unless @raw['highlighting'].present? && @raw['highlighting'][result_id].present?

    @raw['highlighting'][result_id]
  end
end
#parse_record(@raw['results'][0], false)
#*failing record is a resource with a digital object instance*
