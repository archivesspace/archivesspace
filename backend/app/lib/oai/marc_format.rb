class MARCFormat < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'oai_marc'
    @schema = 'https://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'
  end
end
