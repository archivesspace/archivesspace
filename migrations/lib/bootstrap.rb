# written for Ruby 1.9.3

require_relative "../config/config"
require_relative "../../common/jsonmodel"
JSONModel::init( { :client_mode => true, :url => ASpaceImportConfig::ASPACE_BASE, :strict_mode => true } )
require_relative "../lib/aspace_import"







