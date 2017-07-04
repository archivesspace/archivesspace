class MODSFormat < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'oai_mods'
    @schema = 'https://www.loc.gov/standards/mods/v3/mods-3-6.xsd'
    @namespace = 'http://www.loc.gov/mods/v3'
  end
end
