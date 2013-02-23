ASpaceExport::serializer :dc do
  
  def build(dc, opts = {})

    builder = Nokogiri::XML::Builder.new do |xml|
      _root(dc, xml)     
    end   
    
    builder
  end
  
  def serialize(dc, opts = {})

    builder = build(dc, opts)
    
    builder.to_xml   
  end
  
  private

  def _root(dc, xml)

    xml.metadata('xmlns:dc' => 'http://purl.org/dc/elements/1.1/', 
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => 'http://dublincore.org/schemas/xmls/simpledc20021212.xsd'){
               
      xml['dc'].title dc.title
      
      xml['dc'].identifier dc.identifier
      
      dc.creators.each {|c| xml['dc'].creator c }
      
      dc.subjects.each {|s| xml['dc'].subject s }
      
      dc.sources.each {|s| xml['dc'].source s }
      
      dc.dates.each {|d| xml['dc'].date d }
      
      xml['dc'].type dc.type
      
      xml['dc'].language dc.language

      dc.rights.each {|r| xml['dc'].rights r }

    }
      
  end
end
