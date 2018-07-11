class MARCFormat < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'oai_marc'
    @schema = 'https://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'
    @namespace = 'http://www.loc.gov/MARC21/slim'
  end
end
