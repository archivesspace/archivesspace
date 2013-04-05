YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/templates'
require 'sinatra'

require 'jsonmodel'
require_relative '../backend/app/model/backend_enum_source.rb'

require_relative '../backend/app/lib/username.rb'

include JSONModel

JSONModel::init(:enum_source => BackendEnumSource)

require_relative '../backend/app/lib/rest.rb'


Dir[File.dirname(__FILE__) + '../backend/app/model/*.rb'].each {|file| require file }

require_relative 'handler'
require_relative 'schema_object'
# require_relative 'endpoint_object'
