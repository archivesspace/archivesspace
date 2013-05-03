ASpaceImport::Importer.importer :marcxml do
  
  require_relative '../lib/xml_dom'
  include ASpaceImport::XML::DOM

  def self.profile
    "Imports MARC XML To ArchivesSpace \t (flags: subjects_and_agents_only)"
  end


  def configuration
    
    config = super
    
    if @flags['subjects_and_agents_only']
      config['//record'][:map].select {|key, val| [
          "//datafield[@tag='600'][@ind1='1']", 
          "//datafield[@tag='600'][@ind1='3']",
          "//datafield[@tag='610']", 
          "//datafield[@tag='630']",
          "//datafield[@tag='650']",
          "//datafield[@tag='651']",
          "//datafield[@tag='655']",
          
          ].include?(key) }
    else
      config
    end
    
  end

  
  def self.configure 
    {
      "//record" => {
        :obj => :resource,
        :defaults => {
          :level => 'collection',
        },
        :map => {
          
          #SUBJECTS (UNIFORM)
          "//datafield[@tag='630']" => subject_template('uniform_title'),
          
          #SUBJECTS (TOPICAL)
          "//datafield[@tag='650']" => subject_template('topical'),
          
          #SUBJECTS (Geographic)
          "//datafield[@tag='651']" => subject_template('geographic'),
      
          #SUBJECTS (Genre / form)
          "//datafield[@tag='655']" => subject_template('genre_form'),
          
          # SUBJECTS (Occupation)
          "//datafield[@tag='656']" => subject_template('occupation'),
          
          # SUBJECTS (Function)
          "//datafield[@tag='657']" => subject_template('function'),
          

          # LINKED AGENTS (CORPORATE)
          "//datafield[@tag='610']" => {
            :obj => :agent_corporate_entity,
            :rel => Proc.new {|obj, agent|
              obj[:linked_agents] << {
                :role => 'subject',
                :ref => agent.uri
              }  
            },
            :map => {
              # NAMES (CORPORATE)
              "self::datafield" => {
                :obj => :name_corporate_entity,
                :rel => :names,
                :map => {  
                  "subfield[@code='a']" => :primary_name,
                  "subfield[@code='b']" => :subordinate_name_1,
                  "subfield[@code='c']" => :subordinate_name_2,
                  "subfield[@code='n']" => :number,
                  "subfield[@code='g']" => :qualifier,
                  "subfield[@code='2']" => :source
                },
                :defaults => {
                  :source => 'local',
                  :primary_name => 'primary name',
                }
              }
            }
          },

          # LINKED AGENTS (FAMILY)
          "//datafield[@tag='600'][@ind1='3']" => {
            :obj => :agent_family,
            :rel => Proc.new {|obj, agent|
              obj[:linked_agents] << {
                :role => 'subject',
                :ref => agent.uri
              }  
            },
            :map => {
              # NAMES (FAMILY)
              "self::datafield" => {
                :obj => :name_family,
                :rel => :names,
                :map => {  
                  "subfield[@code='a']" => :family_name,
                  "subfield[@code='c']" => :prefix,
                  "subfield[@code='g']" => :qualifier,
                  "subfield[@code='2']" => :source
                },
                :defaults => {
                  :source => 'local'
                }
              }
            }
          },
          
          # LINKED AGENTS (PERSON)
          "//datafield[@tag='600'][@ind1='1']" => {
            :obj => :agent_person,
            :rel => Proc.new {|obj, agent|
              obj[:linked_agents] << {
                :role => 'subject',
                :ref => agent.uri
              }  
            },
            :map => {
              # NAMES (PERSON)
              "self::datafield" => {
                :obj => :name_person,
                :rel => :names,
                :map => {
                  "subfield[@code='a']" => Proc.new {|name, node|
                    name[:primary_name] = node.inner_text.sub(/,\\s.*$/, '')
                    name[:rest_of_name] = node.inner_text.sub(/^.*,\\s/, '')
                    name[:name_order] = 'direct'
                  },
                  "subfield[@code='b']" => :number,
                  "subfield[@code='c']" => Proc.new {|name, node|
                    val = node.inner_text
                    name[:prefix] = val.sub(/,\\s.*$/, '')
                    name[:title] = val.sub(/^[^,]*,\\s/, '').sub(/,\\s.*$/, '')
                    name[:suffix] = val.sub(/^.*,\\s/, '')
                  },
                  "subfield[@code='d']" => :dates,
                  "subfield[@code='q']" => :fuller_form,
                  "subfield[@code='g']" => :qualifier,
                  "subfield[@code='2']" => :source
                  
                },
                :defaults => {
                  :source => 'local',
                  :rules => 'local',
                  :primary_name => 'primary name'
                }
              }            
            }
          },
          
          
          # TITLE
          "child::datafield[@tag='245']/subfield[@code='a']" => :title,
        
          # LANGUAGE
          "child::datafield[@tag='040']/subfield[@code='b']" => :language,
        
          # ID_0, ID_1, ID_2, ID_3
          "child::datafield[@tag='099']/subfield[@code='a']" => Proc.new {|resource, node|
            node.inner_text.split(/[\s\-_]+/).each_with_index do |val, i|
              resource.send("id_#{i}=", val)
            end
          },
        
          # EXTENTS
          "child::datafield[@tag='300']" => {
            :obj => :extent,
            :rel => :extents,
            :map => {       
               "child::subfield[@code='a']" => Proc.new {|extent, node|
                 extent.number = node.inner_text.gsub(/[^0-9\\.]/, '')
                 extent.extent_type = node.inner_text.gsub(/^[0-9\\.\\s]+/, '')
               }
            },
            :defaults => {:portion => 'whole'}
          },
        
          # ARRANGEMENT NOTE
          "child::datafield[@tag='351']" => {
            :obj => :note_multipart,
            :rel => :notes,
            :map => {
              "child::subfield[@code='b']" => Proc.new {|note, node|
                note.send('label=', node.inner_text)
                note.content << node.inner_text 
              }
            },
            :defaults => {
              :type => 'arrangement',
            }
          },
        
          # GENERAL NOTE
          "child::datafield[@tag='500' or @tag='535' or @tag='540' or @tag='546']" => note_template('odd'),
        
          # ACCESS RESTRICT NOTE
          "child::datafield[@tag='506']" => note_template('accessrestrict'),
        
          # SCOPE CONTENT NOTE
          "child::datafield[@tag='520']" => note_template('scopecontent'),
        
          # PREFERRED CITATION NOTE
          "child::datafield[@tag='524']" => note_template('prefercite'),
                  
          # ACQUISITION NOTE
          "child::datafield[@tag='541']" => note_template('acqinfo'),
        
          # RELATED MATERIALS NOTE
          "child::datafield[@tag='544']" => note_template('relatedmaterial'),
        
          # BIOGRAPHICAL NOTE
          "child::datafield[@tag='545']" => note_template('bioghist'),
                  
          # OTHER FINDING AID NOTE
          "child::datafield[@tag='555']" => {
            :obj => :note_multipart,
            :rel => :notes,
            :map => {
              "child::subfield[@code='a']" => :label,
              "subfield[@code='u']" => :content
            },
            :defaults => {
              :type => 'otherfindaid',
            }
          },
        
          # CUSTODIAL NOTE
          "child::datafield[@tag='561']" => {
            :obj => :note_multipart,
            :rel => :notes,
            :map => {
              "child::subfield" => Proc.new {|note, node|
                note.send('label=', node.inner_text)
                note.content << node.inner_text 
              }
            },
            :defaults => {
              :type => 'custodhist',
            }
          },
        
          # APPRAISAL NOTE
          "child::datafield[@tag='583']" => {
            :obj => :note_multipart,
            :rel => :notes,
            :map => {
              "child::subfield" => Proc.new {|note, node|
                note.send('label=', node.inner_text)
                note.content << node.inner_text 
              }
            },
            :defaults => {
              :type => 'appraisal',
            }
          },
        
          # ACCRUALS NOTE
          "child::datafield[@tag='584']" => {
            :obj => :note_multipart,
            :rel => :notes,
            :map => {
              "child::subfield" => Proc.new {|note, node|
                note.send('label=', node.inner_text)
                note.content << node.inner_text 
              }
            },
            :defaults => {
              :type => 'accruals',
            }
          },
        }
      }
    }
  end
  
  private
  
  def self.subject_template(term_type)
    {
      :obj => :subject,
      :rel => :subjects,
      :map => {
        "subfield[@code='a']" => {
          :obj => :term,
          :rel => :terms,
          :map => {
            "self::subfield" => :term
          },
          :defaults => {
            :term_type => term_type,
            :vocabulary => '/vocabularies/1'
          }
        }
      },
      :defaults => {
        :vocabulary => '/vocabularies/1'
      }
    }
  end
  
  
  def self.note_template(note_type)
    {
      :obj => :note_multipart,
      :rel => :notes,
      :map => {
        "child::subfield[@code='a']" => Proc.new {|note, node|
          note.send('label=', node.inner_text)
          note.content << node.inner_text 
        }
      },
      :defaults => {
        :type => note_type,
      }
    }
  end
end

 

