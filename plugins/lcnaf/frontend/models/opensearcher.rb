require 'net/http'
require 'nokogiri'
require 'asutils'
require_relative 'opensearchresultset'

LCNAF='https://id.loc.gov/authorities/names'
LCSH='https://id.loc.gov/authorities/subjects'

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


  # ANW-429: this method writes two tempfiles -- one for agents records and one for subject records so that the correct importer (MARC auth for agents, MARC bib for subjects is used.
  def results_to_marcxml_file(lccns)
    agent_tempfile = ASUtils.tempfile('lcnaf_import_agent')
    subject_tempfile = ASUtils.tempfile('lcnaf_import_subject')

    agents_count = 0
    subjects_count = 0

    agent_tempfile.write("<collection>\n")
    subject_tempfile.write("<collection>\n")

    lccns.each do |lccn|
      lccn.sub!( 'info:lc/authorities/subjects/', '')
      uri = URI("#{@scheme}/#{lccn}.marcxml.xml")

      HTTPRequest.new.get(uri) do |response|
        response = status_check(response)

        doc = Nokogiri::XML.parse(response.body) do |config|
          config.default_xml.noblanks
        end

        doc.remove_namespaces!
        doc.encoding = 'utf-8'

        if is_subject_record?(doc)
          subject_tempfile.write(doc.root)
          subjects_count += 1
        else
          agent_tempfile.write(doc.root)
          agents_count += 1
        end
      end
    end

    agent_tempfile.write("\n</collection>")
    subject_tempfile.write("\n</collection>")

    agent_tempfile.flush
    subject_tempfile.flush

    agent_tempfile.rewind
    subject_tempfile.rewind

    return {
             :agents => {:count => agents_count, :file => agent_tempfile}, 
             :subjects => {:count => subjects_count, :file => subject_tempfile}
           }
  end

  def is_subject_record?(doc)
    is_subject_record = false

    subject_tags = ["630", "130", "650", "150", "651", "151", "655", "155", "656", "657", "690", "691", "692", "693", "694", "695", "696", "697", "698", "699"]


    subject_tags.each do |tag|
      if doc.search("//datafield[@tag='#{tag}']").length > 0
        is_subject_record = true
        break
      end
    end

    is_subject_record
  end


  def search(query, page, records_per_page)
    uri = URI(@base_url)
    start_record = calculate_start_record(page, records_per_page)
    params = default_params.merge('q' => [query.to_s, 'cs:' + @scheme],
                                  'count' => records_per_page,
                                  'start' => start_record)

    uri.query = URI.encode_www_form(params)
    results = HTTPRequest.new.get(uri) do |response|
      response = status_check(response)

      OpenSearchResultSet.new(response.body, query)
    end

    results.entries.each do |entry|
      marc_uri = URI("#{entry['uri']}.marcxml.xml")

      HTTPRequest.new.get(marc_uri) do |response|
        response = status_check(response)

        entry['xml'] = response.body.force_encoding("iso-8859-1").encode('utf-8')
      end
    end

    results
  end

  def status_check(response)
    if response.is_a?(Net::HTTPMovedPermanently)
      uri = URI(response['location'])
      response = Net::HTTP.get_response(uri)
    elsif !(response.is_a?(Net::HTTPOK))
      raise OpenSearchException.new("Error during OpenSearch search: #{response.body}")
    else
      response
    end
  end

end
