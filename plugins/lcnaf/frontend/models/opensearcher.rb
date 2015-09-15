require 'net/http'
require 'nokogiri'
require 'asutils'
require_relative 'opensearchresultset'

LCNAF='http://id.loc.gov/authorities/names'
LCSH='http://id.loc.gov/authorities/subjects'

class OpenSearcher
  attr_accessor :scheme


  class OpenSearchException < StandardError; end

  def initialize(base_url, scheme )
    @base_url = base_url
    @scheme = scheme
  end


  def default_params
    {
      'format' => 'json'
    }
  end


  def calculate_start_record(page, records_per_page)
    ((page - 1) * records_per_page) + 1
  end


  def results_to_marcxml_file(lccns)
    tempfile = ASUtils.tempfile('lcnaf_import')
    tempfile.write("<collection>\n")

    lccns.each do |lccn|
      lccn.sub!( 'info:lc/authorities/subjects/', '')
      uri = URI("#{@scheme}/#{lccn}.marcxml.xml")

      response = Net::HTTP.get_response(uri)
      if response.code != '200'
        raise OpenSearchException.new("Error during OpenSearch search: #{response.body}")
      end

      doc = Nokogiri::XML.parse(response.body) do |config|
        config.default_xml.noblanks
      end

      doc.remove_namespaces!
      doc.encoding = 'utf-8'

      tempfile.write(doc.root)
    end

    tempfile.write("\n</collection>")

    tempfile.flush
    tempfile.rewind

    return tempfile
  end


  def search(query, page, records_per_page)
    uri = URI(@base_url)
    start_record = calculate_start_record(page, records_per_page)
    params = default_params.merge('q' => [query.to_s, @scheme],
                                  'count' => records_per_page,
                                  'start' => start_record)

    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    if response.code != '200'
      raise OpenSearchException.new("Error during OpenSearch search: #{response.body}")
    end

    results = OpenSearchResultSet.new(response.body, query)

    results.entries.each do |entry|
      marc_uri = URI("#{entry['uri']}.marcxml.xml")
      response = Net::HTTP.get_response(marc_uri)
      if response.code != '200'
        raise OpenSearchException.new("Error during OpenSearch search: #{response.body}")
      end

      entry['xml'] = response.body.force_encoding("iso-8859-1").encode('utf-8')
    end

    results
  end
  
end
