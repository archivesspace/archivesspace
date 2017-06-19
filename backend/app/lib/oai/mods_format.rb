class MODSFormat < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'oai_mods'
    @schema = 'https://www.loc.gov/standards/mods/v3/mods-3-6.xsd'
  end
end
