require "jsonmodel"

JSONModel::init(:client_mode => true,
                :url => ArchivesSpace::Application.config.backend_url)

include JSONModel

