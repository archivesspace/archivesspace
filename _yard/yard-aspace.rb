YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/templates'
require 'sinatra'
require_relative '../common/jsonmodel.rb'
require_relative '../backend/app/controllers/setup.rb'
require_relative '../backend/app/lib/rest.rb'
Dir[File.dirname(__FILE__) + '../backend/app/model/*.rb'].each {|file| require file }
require_relative 'handler'
require_relative 'schema_object'
require_relative 'endpoint_object'
