require_relative 'converter'
require_relative 'lib/marcxml_auth_subject_base_map'

class MarcXMLAuthSubjectConverter < Converter
  extend MarcXMLAuthSubjectBaseMap

  require 'securerandom'
  require_relative 'lib/xml_dom'
  include ASpaceImport::XML::DOM

  def self.instance_for(type, input_file)
    if type == "marcxml_auth_subject"
      self.new(input_file)
    else
      nil
    end
  end

  def self.import_types(show_hidden = false)
    [
     {
       :name => "marcxml_auth_subject",
       :description => "Import subject records from a MARCXML authority file"
     }
    ]
  end
end

MarcXMLAuthSubjectConverter.configure do |config|
  config.init_map(MarcXMLAuthSubjectConverter.BASE_RECORD_MAP)
end
