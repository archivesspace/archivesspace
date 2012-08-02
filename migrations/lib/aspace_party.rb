require 'httparty'

class ASpaceParty
  include HTTParty
  base_uri ASpaceImportConfig::ASPACE_BASE
end

