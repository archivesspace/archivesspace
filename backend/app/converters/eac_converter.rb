require_relative 'converter'

class EACConverter < Converter

  require_relative 'lib/xml_dom'
  include ASpaceImport::XML::DOM


  def self.instance_for(type, input_file)
    if type == "eac_xml"
      self.new(input_file)
    else
      nil
    end
  end


  def self.import_types(show_hidden = false)
    [
     {
       :name => "eac_xml",
       :description => "Import EAC-CPF records from an XML file"
     }
    ]
  end


  def self.profile
    "Convert EAC-CPF To ArchivesSpace JSONModel records"
  end


  def self.configure
    {

      # AGENT PERSON
      "//cpfDescription[child::identity/child::entityType='person']" => {
        :obj => :agent_person,

        :map => {
          # NAMES (PERSON)
          "descendant::nameEntry" => {
            :obj => :name_person,
            :rel => :names,
            :map => {
              "descendant::part" => Proc.new {|name, node|
                val = node.inner_text
                name[:primary_name] = val
                name[:dates] = val.scan(/[0-9]{4}-[0-9]{4}/).flatten[0]
              },
            },
            :defaults => {
              :source => 'local',
              :rules => 'local',
              :primary_name => 'primary name',
              :name_order => 'direct',
            }
          },
          "descendant::biogHist" => {
            :obj => :note_bioghist,
            :rel => :notes,
            :map => {
              "self::biogHist" => Proc.new {|note, node|
                note['subnotes'] << {
                  'jsonmodel_type' => 'note_text',
                  'content' => node.inner_text
                }
              }
            },
            :defaults => {
              :label => 'default label'
            }
          }
        }
      }

    }
  end

end
