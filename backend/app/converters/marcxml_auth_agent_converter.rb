require_relative 'converter'
require_relative 'lib/marcxml_auth_agent_base_map'

class MarcXMLAuthAgentConverter < Converter
  extend MarcXMLAuthAgentBaseMap

  require 'securerandom'
  require_relative 'lib/xml_dom'
  include ASpaceImport::XML::DOM


  def self.instance_for(type, input_file)
    if type == "marcxml_auth_agent"
      self.new(input_file)
    else
      nil
    end
  end

  def set_import_events
    config.init_map(MarcXMLAuthAgentConverter.BASE_RECORD_MAP(true))
  end

  def unset_import_events
    config.init_map(MarcXMLAuthAgentConverter.BASE_RECORD_MAP(false))
  end

  def self.import_types(show_hidden = false)
    [
     {
       :name => "marcxml_auth_agent",
       :description => "Import agent records from a MARCXML authority file"
     }
    ]
  end
end

MarcXMLAuthAgentConverter.configure do |config|
  config.init_map(MarcXMLAuthAgentConverter.BASE_RECORD_MAP)
end


