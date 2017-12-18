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

  private

  def parse_records(full)
    Array(@raw['results']).map {|result| parse_record(result, full) }
  end

  def parse_record(result, full)
    record = record_for_type(result, full)
    record.criteria = @search_opts

    record
  end

  def [](k)
    # $stderr.puts "FIXME stop direct access to the results json blob ([]): #{caller.first}"
    raw[k]
  end
end
