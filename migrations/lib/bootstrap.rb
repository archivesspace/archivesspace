# written for Ruby 1.9.3

require_relative "../config/config"
require_relative "../../common/jsonmodel"
require_relative File.join("..", "lib", "jsonmodel_queue")
JSONModel::init( { :client_mode => true, :url => ASpaceImportConfig::ASPACE_BASE, :strict_mode => true } )
require_relative File.join("..", "lib", "importer")
require_relative File.join("..", "lib", "crosswalk")









