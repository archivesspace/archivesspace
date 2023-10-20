require_relative 'converter'

class DigitalObjectConverter < Converter

  require_relative 'lib/csv_converter'
  include ASpaceImport::CSVConvert


  def self.import_types(show_hidden = false)
    [
     {
       :name => "digital_object_csv",
       :description => "Import Digital Object records from a CSV file"
     }
    ]
  end


  def self.instance_for(type, input_file)
    if type == "digital_object_csv"
      self.new(input_file)
    else
      nil
    end
  end


  def self.configure
    {
      # 1. Map the cell data to schemas or handlers

      'agent_role' => 'd.agent_role',
      'agent_type' => 'agent.agent_type',

      'agent_contact_address_1' => 'agent_contact.address_1',
      'agent_contact_address_2' => 'agent_contact.address_2',
      'agent_contact_address_3' => 'agent_contact.address_3',
      'agent_contact_city' => 'agent_contact.city',
      'agent_contact_country' => 'agent_contact.country',
      'agent_contact_email' => 'agent_contact.email',
      'agent_contact_fax' => 'agent_contact.fax',
      'agent_contact_name' => 'agent_contact.name',

      'agent_contact_post_code' => 'agent_contact.post_code',
      'agent_contact_region' => 'agent_contact.region',
      'agent_contact_salutation' => 'agent_contact.salutation',
      'agent_contact_telephone' => 'agent_contact.telephone',
      'agent_contact_telephone_ext' => 'agent_contact.telephone_ext',

      'agent_name_authority_id' => 'agent_name.authority_id',
      'agent_name_dates' => 'agent_name.dates',
      'agent_name_fuller_form' => 'agent_name.fuller_form',
      'agent_name_name_order' => 'agent_name.name_order',
      'agent_name_number' => 'agent_name.number',
      'agent_name_prefix' => 'agent_name.prefix',
      'agent_name_primary_name' => 'agent_name.primary_name',
      'agent_name_qualifier' => 'agent_name.qualifier',
      'agent_name_rest_of_name' => 'agent_name.rest_of_name',
      'agent_name_rules' => 'agent_name.rules',
      'agent_name_sort_name' => 'agent_name.sort_name',
      'agent_name_source' => 'agent_name.source',
      'agent_name_subordinate_name_1' => 'agent_name.subordinate_name_1',
      'agent_name_subordinate_name_2' => 'agent_name.subordinate_name_2',
      'agent_name_suffix' => 'agent_name.suffix',

      'agent_name_description_note' => 'note_bioghist.content',
      'agent_name_description_citation' => 'note_citation.content',
      # 'agent_name_description_type' => '',

      'digital_object_acknowledgement_sent' => [normalize_boolean, 'acknowledgement_sent_event_date.boolean'],
      'digital_object_acknowledgement_sent_date' => [date_flip, 'acknowledgement_sent_event_date.expression'],

      'digital_object_agreement_received' => [normalize_boolean, 'agreement_received_event_date.boolean'],
      'digital_object_agreement_received_date' => [date_flip, 'agreement_received_event_date.expression'],

      'digital_object_agreement_sent' => [normalize_boolean, 'agreement_sent_event_date.boolean'],
      'digital_object_agreement_sent_date' => [date_flip, 'agreement_sent_event_date.expression'],

      'digital_object_cataloged' => [normalize_boolean, 'cataloged_event_date.boolean'],
      'digital_object_cataloged_date' => [date_flip, 'cataloged_event_date.expression'],

      'digital_object_processed' => [normalize_boolean, 'processed_event_date.boolean'],
      'digital_object_processed_date' => [date_flip, 'processed_event_date.expression'],
      'digital_object_processing_started_date' => 'collection_management.processing_started_date',
      'digital_object_processing_estimate' => 'collection_management.processing_hours_per_foot_estimate',
      'digital_object_processing_hours_total' => 'collection_management.processing_hours_total',
      'digital_object_processing_plan' => 'collection_management.processing_plan',
      'digital_object_processing_priority' => 'collection_management.processing_priority',

      # 'digital_object_processing_started_date' => '',
      'digital_object_processing_status' => 'collection_management.processing_status',
      'digital_object_processing_total_extent' => 'collection_management.processing_total_extent',
      'digital_object_processing_total_extent_type' => 'collection_management.processing_total_extent_type',
      'digital_object_processors' => 'collection_management.processors',

      'digital_object_rights_determined' => 'collection_management.rights_determined',
      # 'digital_object_rights_transferred' => '',
      # 'digital_object_rights_transferred_date' => '',
      # 'digital_object_rights_transferred_note' => '',

      'digital_object_title' => 'd.title',
      'digital_object_id' => 'd.digital_object_id',
      'digital_object_is_component' => [normalize_boolean, 'd.is_component'],
      'digital_object_component_id' => 'd.component_id',

      'digital_object_cataloged_note' => 'collection_management.cataloged_note',

      'digital_object_language' => 'lang_material.language',
      'digital_object_script' => 'lang_material.script',

      'digital_object_level' => 'd.level',
      'digital_object_publish' => [normalize_boolean, 'd.publish'],
      'digital_object_type' => 'd.digital_object_type',
      'digital_object_restrictions' => [normalize_boolean, 'd.restrictions'],

      'date_1_label' => 'date_1.label',
      'date_1_expression' => 'date_1.expression',
      'date_1_begin' => 'date_1.begin',
      'date_1_end' => 'date_1.end',
      'date_1_type' => 'date_1.date_type',

      'date_2_label' => 'date_2.label',
      'date_2_expression' => 'date_2.expression',
      'date_2_begin' => 'date_2.begin',
      'date_2_end' => 'date_2.end',
      'date_2_type' => 'date_2.date_type',

      'extent_type' => 'extent.extent_type',
      'extent_container_summary' => 'extent.container_summary',
      'extent_number' => 'extent.number',
      'extent_physical_details' => 'extent.physical_details',
      'extent_portion' => 'extent.portion',
      'extent_dimensions' => 'extent.dimensions',
      'extent_container_summary' => 'extent.container_summary',

      'subject_source' => 'subject.source',
      'subject_term' => 'subject.term',
      'subject_term_type' => 'subject.term_type',

      'user_defined_boolean_1' => [normalize_boolean, 'user_defined.boolean_1'],
      'user_defined_boolean_2' => [normalize_boolean, 'user_defined.boolean_2'],
      'user_defined_boolean_3' => [normalize_boolean, 'user_defined.boolean_3'],
      'user_defined_date_1' => [date_flip, 'user_defined.date_1'],
      'user_defined_date_2' => [date_flip, 'user_defined.date_2'],
      'user_defined_date_3' => [date_flip, 'user_defined.date_3'],
      'user_defined_integer_1' => [to_int, 'user_defined.integer_1'],
      'user_defined_integer_2' => [to_int, 'user_defined.integer_2'],
      'user_defined_integer_3' => [to_int, 'user_defined.integer_3'],
      'user_defined_real_1' => [to_real, 'user_defined.real_1'],
      'user_defined_real_2' => [to_real, 'user_defined.real_2'],
      'user_defined_real_3' => [to_real, 'user_defined.real_3'],
      'user_defined_string_1' => 'user_defined.string_1',
      'user_defined_string_2' => 'user_defined.string_2',
      'user_defined_string_3' => 'user_defined.string_3',
      'user_defined_string_4' => 'user_defined.string_4',
      'user_defined_text_1' => 'user_defined.text_1',
      'user_defined_text_2' => 'user_defined.text_2',
      'user_defined_text_3' => 'user_defined.text_3',
      'user_defined_text_4' => 'user_defined.text_4',
      'user_defined_text_5' => 'user_defined.text_5',
      'user_defined_enum_1' => 'user_defined.enum_1',
      'user_defined_enum_2' => 'user_defined.enum_2',
      'user_defined_enum_3' => 'user_defined.enum_3',
      'user_defined_enum_4' => 'user_defined.enum_4',

      'file_version_file_uri' => 'file_version.file_uri',
      'file_version_publish' => [normalize_boolean, 'file_version.publish'],
      'file_version_use_statement' => 'file_version.use_statement',
      'file_version_xlink_actuate_attribute' => 'file_version.xlink_actuate_attribute',
      'file_version_xlink_show_attribute' => 'file_version.xlink_show_attribute',
      'file_version_file_format_name' => 'file_version.file_format_name',
      'file_version_file_format_version' => 'file_version.file_format_version',
      'file_version_file_size_bytes' => 'file_version.file_size_bytes',
      'file_version_checksum' => 'file_version.checksum',
      'file_version_checksum_method' => 'file_version.checksum_method',
      'file_version_is_representative' => [normalize_boolean, 'file_version.is_representative'],
      'file_version_caption' => 'file_version.caption',

      # 2. Define data handlers
      #    :record_type of the schema (if other than the handler key)
      #    :defaults - hash which maps property keys to default values if nothing shows up in the source date
      #    :on_row_complete - Proc to run whenever a row in the CSV table is complete
      #        param 1 is the set of objects generated by the row
      #        param 2 is an object in the row (of the type described in the handler)

      :acknowledgement_sent_event_date => event_template('acknowledgement_sent'),

      :agreement_received_event_date => event_template('agreement_received'),

      :agreement_sent_event_date => event_template('agreement_sent'),

      :cataloged_event_date => event_template('cataloged'),

      :processed_event_date => event_template('processed'),


      :agent => {
        :record_type => Proc.new {|data|
            @agent_type = data['agent_type']
          },
        :on_row_complete => Proc.new {|cache, agent|
            digital_object = cache.find {|obj| obj.class.record_type == 'digital_object' }

            if digital_object
              digital_object.linked_agents[0]['ref'] = agent.uri
            else
              cache.reject! {|obj| obj.key == agent.key}
            end
          },

      },

      :agent_contact => {
        :on_row_complete => Proc.new {|cache, this|
          agent = cache.find {|obj| obj.class.record_type =~ /^agent_(perso|corpo|famil)/}
          agent.agent_contacts << this
        }
      },

      :agent_name => {
        :record_type => Proc.new {|data|
          @agent_type.sub(/agent_/, 'name_')
        },
        :on_create => Proc.new {|data, obj|
          if @agent_type =~ /family/
            obj.family_name = data['primary_name']
          end
        },
        :on_row_complete => Proc.new {|cache, this|
          agent = cache.find {|obj| obj.class.record_type =~ /^agent_(perso|corpo|famil)/}
          agent.names << this
        }
      },

      # this might be a Digital Object, or it might be a Digital Object Component
      :d => {
        :record_type => Proc.new {|data|
          data['is_component'] ? :digital_object_component : :digital_object
        },
        :on_create => Proc.new {|data, obj|
          if obj.class.record_type == 'digital_object_component'

            unless data['digital_object_id']
              raise "Component entries must have a 'digital_object_id' to link them to a top-level record"
            end

            do_uri = uri_lookup[data['digital_object_id']]

            unless do_uri
              raise "Components must be preceded by their top-level digital object in the CSV"
            end

            obj.digital_object = {'ref' => do_uri}
          else

            if data['agent_role']
              obj.linked_agents << {'role' => data['agent_role']}
            end
          end

        },
        :on_row_complete => Proc.new { |cache, obj|
          case
          when obj.class.record_type == 'digital_object'

            uri_lookup[obj.digital_object_id] = obj.uri

            if (cm = cache.find {|obj| obj.class.record_type == 'collection_management'})
              obj.collection_management = cm
            end

          else
            # ignore collection management data in a component context
            cache.reject! {|obj| obj.class.record_type == 'collection_management'}
          end
        }
      },

      :date_1 => {
        :record_type => :date,
        :defaults => date_defaults,
        :on_row_complete => attach_date,
      },

      :date_2 => {
        :record_type => :date,
        :defaults => date_defaults,
        :on_row_complete => attach_date,
      },

      :extent => {
        :defaults => {:portion => 'whole'},
        :on_row_complete => Proc.new {|cache, extent|
          digital_object = cache.find {|obj| obj.class.record_type =~ /^digital_object/ }
          digital_object.extents << extent
        }
      },

      :lang_material => {
        :on_create => Proc.new {|data, obj|
          obj.language_and_script = {'jsonmodel_type' => 'language_and_script', 'language' => data['language'], 'script' => data['script']}
        },
        :on_row_complete => Proc.new {|cache, this|
          digital_object = cache.find {|obj| obj.class.record_type =~ /^digital_object/ }
          digital_object.lang_materials << this
        }
      },

      :note_bioghist => {
        :on_create => Proc.new {|data, obj|
          obj.subnotes = [{'jsonmodel_type' => 'note_text', 'content' => data['content']}]
        },
        :on_row_complete => Proc.new {|cache, this|
          agent = cache.find {|obj| obj.class.record_type =~ /^agent_(perso|fami|corpo)/}
          agent.notes << this
        }
      },

      :note_citation => {
        :on_row_complete => Proc.new {|cache, this|
          note_biogist = cache.find {|obj| obj.class.record_type == 'note_bioghist'}
          note_biogist.subnotes << this
        }
      },

      :subject => {
        :on_create => Proc.new {|data, obj|
          obj.terms = [{:term => data['term'], :term_type => data['term_type'], :vocabulary => '/vocabularies/1'}]
          obj.vocabulary = '/vocabularies/1'
        },
        :on_row_complete => Proc.new {|cache, this|
          digital_object = cache.find {|obj| obj.class.record_type == 'digital_object'}
          digital_object.subjects << {'ref' => this.uri}
        }
      },

      :user_defined => {
        :on_row_complete => Proc.new {|cache, this|
          digital_object = cache.find {|obj| obj.class.record_type == 'digital_object'}
          digital_object.user_defined = this
        }
      },

      :file_version => {
        :on_row_complete => Proc.new {|cache, this|
          digital_object = cache.find {|obj| obj.class.record_type =~ /^digital_object/ }
          digital_object.file_versions << this
        }
      },
    }
  end


  private

  def self.event_template(event_type)
    {
      :record_type => Proc.new {|data|
        data['boolean'] ? :date : nil
      },
      :defaults => date_defaults,
      :on_create => Proc.new {|data, obj|
        obj.expression = 'unknown' unless data['expression']
      },
      :on_row_complete => Proc.new { |cache, date|
        digital_object = cache.find {|obj| obj.class.record_type == 'digital_object'}
        event = ASpaceImport::JSONModel(:event).new
        cache << event
        event.event_type = event_type
        # Not sure how best to handle this, assuming for now that the built-in ASpace agent exists:
        event.linked_agents << {'role' => 'executing_program', 'ref' => '/agents/software/1'}
        event.date = date
        event.linked_records << {'role' => 'source', 'ref' => digital_object.uri}
      }
    }
  end


  def self.date_defaults
    {
      :label => 'other',
      :date_type => 'single',
      :begin => '1900'
    }
  end


  def self.attach_date
    Proc.new { |cache, date|
      digital_object = cache.find {|obj| obj.class.record_type =~ /^digital_object/ }
      digital_object.dates << date
    }
  end


  def self.normalize_boolean
    @normalize_boolean ||= Proc.new {|val| val.to_s.upcase.match(/\A(1|T|Y|YES|TRUE)\Z/) ? true : false }
    @normalize_boolean
  end


  #need to track relationships across rows
  def self.uri_lookup
    @uri_lookup ||= {}
    @uri_lookup
  end


  # need to resue the agent type
  def self.agent_type
    @agent_type ||= nil
    @agent_type
  end


  def self.date_flip
    @date_flip ||= Proc.new {|val| val.sub(/^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})$/, '\2/\1/\3')}

    @date_flip
  end


  def self.to_real
    @to_real ||= Proc.new {|val| "%0.2f" % val.to_f}

    @to_real
  end


  def self.to_int
    @to_int ||= Proc.new {|val| val.to_i.to_s}

    @to_int
  end
end
