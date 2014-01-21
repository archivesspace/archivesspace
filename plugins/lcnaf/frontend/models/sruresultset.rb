require 'asutils'

class SRUResultSet

  attr_reader :hit_count


  def initialize(response_body)
    doc = Nokogiri::XML.parse(response_body)
    doc.remove_namespaces!

    @at_start = doc.xpath("//startRecord").text() == "1"
    @at_end = doc.xpath("//nextRecordPosition").empty?

    @hit_count = doc.xpath("//searchRetrieveResponse/numberOfRecords").text().to_i
    @records = doc.xpath("//recordData/record").map {|record| record.to_xml}
  end


  def at_start?
    @at_start
  end


  def at_end?
    @at_end
  end


  def to_json
    ASUtils.to_json(:records => @records,
                    :at_start => at_start?,
                    :at_end => at_end?,
                    :hit_count => hit_count
                    )
  end

end
