ASpaceImport::Importer.importer :eac do
  
  require_relative '../lib/xml_dom'
  include ASpaceImport::XML::DOM

  def self.profile
    "Imports EAC-CPF To ArchivesSpace"
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
              "self::biogHist" => :content
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

 

