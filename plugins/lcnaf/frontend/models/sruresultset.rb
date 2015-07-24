require 'asutils'

class SRUResultSet

  attr_reader :hit_count


  def initialize(response_body, query, page, records_per_page)
    @query = query
    
    @page = page
    @records_per_page = records_per_page

    doc = Nokogiri::XML.parse(response_body) do |config|
      config.default_xml.noblanks
    end

    doc.remove_namespaces!
    doc.encoding = 'utf-8'
   
    @at_start = doc.xpath("//startRecord").text() == "1"
    @at_end = doc.xpath("//nextRecordPosition").empty?

    @hit_count = doc.xpath("//searchRetrieveResponse/numberOfRecords").text().to_i
    @records = doc.xpath("//recordData/record").map {|record|
      title = "#{record.xpath("./datafield[@tag='100']/subfield[@code='a']").text().strip} "
      if record.xpath("./datafield[@tag='100']/subfield[@code='b']")
        title << "#{record.xpath("./datafield[@tag='100']/subfield[@code='b']").text.strip} " 
      end
      
      if record.xpath("./datafield[@tag='100']/subfield[@code='c']")
        title << record.xpath("./datafield[@tag='100']/subfield[@code='c']").inject("") { |result, node| "#{node.text.strip} " } 
      end
      
      if record.xpath("./datafield[@tag='100']/subfield[@code='q']")
        title << "#{record.xpath("./datafield[@tag='100']/subfield[@code='q']").text.strip} " 
      end
      
      if record.xpath("./datafield[@tag='100']/subfield[@code='d']")
        title << "#{record.xpath("./datafield[@tag='100']/subfield[@code='d']").text.strip} " 
      end
      
      {
        :title => title.strip, 
        :xml => record.to_xml(:indent => 2),
        :lccn => record.xpath("./datafield[@tag='010']/subfield[@code='a']").text().gsub(' ', '')
      }
    }
  end


  def each(&block)
    @records.each do |record|
      yield(record[:xml])
    end
  end


  def at_start?
    @at_start
  end


  def first_record_index
    ((@page - 1) * @records_per_page) + 1
  end


  def last_record_index
    [first_record_index + @records_per_page - 1, @hit_count].min
  end


  def at_end?
    @at_end
  end


  def to_json
    ASUtils.to_json(:records => @records,
                    :at_start => at_start?,
                    :at_end => at_end?,
                    :hit_count => hit_count,
                    :query => @query,
                    :page => @page,
                    :records_per_page => @records_per_page,
                    :first_record_index => first_record_index,
                    :last_record_index => last_record_index
                    )
  end

end
