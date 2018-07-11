class DCSerializer < ASpaceExport::Serializer
  serializer_for :dc

  def build(dc, opts = {})

    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      _root(dc, xml)     
    end   
    
    builder
  end
  
  def serialize(dc, opts = {})

    builder = build(dc, opts)
    
    builder.to_xml   
  end

  def serialize_dc(dc, xml)
    _root(dc, xml) 
  end
  
  private

  def _root(dc, xml)
    schema_locations = "http://purl.org/dc/elements/1.1/ http://dublincore.org/schemas/xmls/qdc/2006/01/06/dc.xsd http://purl.org/dc/terms/ http://dublincore.org/schemas/xmls/qdc/2006/01/06/dcterms.xsd"

    dc_root = xml.dc(
                 'xmlns' => 'http://purl.org/dc/elements/1.1/', 
                 "xmlns:dcterms" => "http://purl.org/dc/terms/",
                 "xmlns:xlink" => "http://www.w3.org/1999/xlink",
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => schema_locations) {

               
      xml.title dc.title
      
      xml.identifier dc.identifier

      if dc.ark_identifier
        xml.location dc.ark_identifier
      end
      
      dc.creators.each {|c| xml.creator c }
      
      dc.subjects.each {|s| xml.subject s }
           
      dc.dates.each {|d| xml.date d }

      %w(description rights format source relation).each do |tag|

        dc.send("each_#{tag}") do |value|
          xml.send(:"#{tag}_", value)
        end
      end

      xml.type dc.type
      
      xml.language dc.language

    }
      
  end
end
