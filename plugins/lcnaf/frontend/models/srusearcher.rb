require 'net/http'
require 'nokogiri'

require_relative 'sruquery'
require_relative 'sruresultset'

class SRUSearcher

  class SRUSearchException < StandardError; end


  def initialize(base_url)
    @base_url = base_url
  end


  def default_params
    {
      'version' => '1.1',
      'operation' => 'searchRetrieve',
      'recordSchema' => 'info:srw/schema/1/marcxml-v1.1',
      'resultSetTTL' => 60,
      'recordPacking' => 'xml'
    }
  end


  def calculate_start_record(page, records_per_page)
    ((page - 1) * records_per_page) + 1
  end


  def search(sru_query, page, records_per_page)
    uri = URI(@base_url)
    start_record = calculate_start_record(page, records_per_page)
    params = default_params.merge('query' => sru_query.to_s,
                                  'maximumRecords' => records_per_page,
                                  'startRecord' => start_record)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    if response.code != '200'
      raise SRUSearchException.new("Error during SRU search: #{response.body}")
    end
    File.open("/tmp/sru.txt", "a+") { |a| a << uri.to_s + "\n" + response.body }
    SRUResultSet.new(response.body, sru_query, page, records_per_page)
  end


  def results_to_marcxml_file(query)
    page = 1
    tempfile = ASUtils.tempfile('lcnaf_import')

    tempfile.write("<collection>\n")

    while true
      results = search(query, page, 10)

      results.each do |xml|
        tempfile.write(xml)
      end

      break if results.at_end?

      page += 1
    end

    tempfile.write("\n</collection>")

    tempfile.flush
    tempfile.rewind

    return tempfile
  end

end
