require_relative 'converter'
require_relative 'lib/marcxml_base_map'

class MarcXMLConverter < Converter
  extend MarcXMLBaseMap

  require 'securerandom'
  require_relative 'lib/xml_dom'
  include ASpaceImport::XML::DOM


  def self.import_types(show_hidden = false)
    [
     {
       :name => "marcxml",
       :description => "Import all record types from a MARC XML file"
     },
     {
       :name => "marcxml_subjects_and_agents",
       :description => "Import only subjects and agents from a MARC XML file"
     }
    ]
  end


  def self.instance_for(type, input_file)
    if type == "marcxml"
      self.new(input_file)
    elsif type == "marcxml_subjects_and_agents"
      self.for_subjects_and_agents_only(input_file)
    else
      nil
    end
  end


  def self.for_subjects_and_agents_only(input_file)
    new(input_file).instance_eval do
      @batch.record_filter = ->(record) {
        AgentManager.known_agent_type?(record.class.record_type) ||
        record.class.record_type == 'subject'
      }

      self
    end
  end


  def self.configure
    super do |config|
      config.doc_frag_nodes << 'record'
      config["/record"] = self.BASE_RECORD_MAP      
      yield config if block_given?
    end
  end
    
end

MarcXMLConverter.configure
