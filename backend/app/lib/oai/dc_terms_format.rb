class DCTermsFormat < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'oai_dcterms'
    @schema = 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/dcterms.xsd'
  end
end
