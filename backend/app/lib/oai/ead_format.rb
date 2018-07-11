class EADFormat < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'oai_ead'
    @schema = 'https://www.loc.gov/ead/ead.xsd'
    @namespace = 'http://www.loc.gov/ead/'
  end
end
