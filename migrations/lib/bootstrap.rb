# written for Ruby 1.9.3

require_relative File.join("..", "config", "config")
require_relative File.join("..", "..", "common", "jsonmodel")
JSONModel::init( { :client_mode => true, :url => ASpaceImportConfig::ASPACE_BASE, :strict_mode => true } )
require_relative File.join("..", "lib", "aspace_import")







