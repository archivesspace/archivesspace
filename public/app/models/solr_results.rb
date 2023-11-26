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
    unless @raw['highlighting'][result['id']].nil?
      record.highlights = @raw['highlighting'][result['id']]
    end
    record
  end
end
