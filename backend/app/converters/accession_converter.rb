require_relative 'converter'
class AccessionConverter < Converter

  require_relative 'lib/csv_converter'
  include ASpaceImport::CSVConvert


  def self.import_types(show_hidden = false)
    [
     {
       :name => "accession_csv",
       :description => "Import Accession records from a CSV file"
     }
    ]
  end

  def self.instance_for(type, input_file)
    if type == "accession_csv"
      self.new(input_file)
    else
      nil
    end
  end


  def self.configure
    {
      # 1. Map the cell data to schemas / handlers
      # {column header} => {data address}
      # or,
      # {column header} => [{filter method}, {data address}]

      'accession_title' => 'accession.title',
      'accession_number_1' => 'accession.id_0',
      'accession_number_2' => 'accession.id_1',
      'accession_number_3' => 'accession.id_2',
      'accession_number_4' => 'accession.id_3',
      'accession_accession_date' => [date_flip, 'accession.accession_date'],
      'accession_access_restrictions' => 'accession.access_restrictions',
      'accession_access_restrictions_note' => 'accession.access_restrictions_note',
      'accession_acquisition_type' => 'accession.acquisition_type',
      'accession_condition_description' => 'accession.condition_description',
      'accession_content_description' => 'accession.content_description',
      'accession_disposition' => 'accession.disposition',
      'accession_general_note' => 'accession.general_note',
      'accession_inventory' => 'accession.inventory',
      'accession_provenance' => 'accession.provenance',
      'accession_publish' => [normalize_boolean, 'accession.publish'],
      'accession_resource_type' => 'accession.resource_type',
      'accession_language' => 'accession.language',
      'accession_script' => 'accession.script',
      'accession_restrictions_apply' => 'accession.restrictions_apply',
      'accession_retention_rule' => 'accession.retention_rule',
      'accession_use_restrictions' => 'accession.use_restrictions',
      'accession_use_restrictions_note' => 'accession.use_restrictions_note',

      'accession_processing_hours_total' => 'collection_management.processing_hours_total',
      'accession_processing_plan' => 'collection_management.processing_plan',
      'accession_processing_priority' => 'collection_management.processing_priority',
      'accession_processing_total_extent' => 'collection_management.processing_total_extent',
      'accession_processing_total_extent_type' => 'collection_management.processing_total_extent_type',
      'accession_processing_status' => 'collection_management.processing_status',
      'accession_processors' => 'collection_management.processors',
      'accession_rights_determined' => 'collection_management.rights_determined',

      'lang_material_language' => 'lang_material.language',
      'lang_material_script' => 'lang_material.script',

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

      'accession_acknowledgement_sent' => [normalize_boolean, 'acknowledgement_sent_event.boolean'],
      'accession_acknowledgement_sent_date' => [date_flip, 'acknowledgement_sent_event.expression'],

      'accession_agreement_received' => [normalize_boolean, 'agreement_received_event.boolean'],
      'accession_agreement_received_date' => [date_flip, 'agreement_received_event.expression'],

      'accession_agreement_sent' => [normalize_boolean, 'agreement_sent_event.boolean'],
      'accession_agreement_sent_date' => [date_flip, 'agreement_sent_event.expression'],

      'accession_cataloged' => [normalize_boolean, 'cataloged_event.boolean'],
      'accession_cataloged_date' => [date_flip, 'cataloged_event.expression'],
      'accession_cataloged_note' => 'cataloged_event.outcome_note',

      'accession_processed' => [normalize_boolean, 'processed_event.boolean'],
      'accession_processed_date' => [date_flip, 'processed_event.expression'],

      'user_defined_boolean_1' => 'user_defined.boolean_1',
      'user_defined_boolean_2' => 'user_defined.boolean_2',
      'user_defined_boolean_3' => 'user_defined.boolean_3',
      'user_defined_integer_1' => 'user_defined.integer_1',
      'user_defined_integer_2' => 'user_defined.integer_2',
      'user_defined_integer_3' => 'user_defined.integer_3',
      'user_defined_real_1' => 'user_defined.real_1',
      'user_defined_real_2' => 'user_defined.real_2',
      'user_defined_real_3' => 'user_defined.real_3',
      'user_defined_string_1' => 'user_defined.string_1',
      'user_defined_string_2' => 'user_defined.string_2',
      'user_defined_string_3' => 'user_defined.string_3',
      'user_defined_string_4' => 'user_defined.string_4',
      'user_defined_text_1' => 'user_defined.text_1',
      'user_defined_text_2' => 'user_defined.text_2',
      'user_defined_text_3' => 'user_defined.text_3',
      'user_defined_text_4' => 'user_defined.text_4',
      'user_defined_text_5' => 'user_defined.text_5',
      'user_defined_date_1' => 'user_defined.date_1',
      'user_defined_date_2' => 'user_defined.date_2',
      'user_defined_date_3' => 'user_defined.date_3',
      'user_defined_enum_1' => 'user_defined.enum_1',
      'user_defined_enum_2' => 'user_defined.enum_2',
      'user_defined_enum_3' => 'user_defined.enum_3',
      'user_defined_enum_4' => 'user_defined.enum_4',

      'agent_role' => 'accession.agent_role',
      'agent_relator' => 'accession.agent_relator',
      'agent_type' => 'agent.agent_type',

      'agent_contact_address_1' => 'agent_contact.address_1',
      'agent_contact_address_2' => 'agent_contact.address_2',
      'agent_contact_address_3' => 'agent_contact.address_3',
      'agent_contact_city' => 'agent_contact.city',
      'agent_contact_country' => 'agent_contact.country',
      'agent_contact_email' => 'agent_contact.email',
      'agent_contact_name' => 'agent_contact.name',

      'agent_contact_post_code' => 'agent_contact.post_code',
      'agent_contact_region' => 'agent_contact.region',
      'agent_contact_salutation' => 'agent_contact.salutation',

      'agent_contact_fax' => 'agent_fax.number',

      'agent_contact_telephone' => 'agent_telephone.number',
      'agent_contact_telephone_ext' => 'agent_telephone.ext',

      'agent_name_authority_id' => 'agent_name.authority_id',
      'agent_name_dates' => 'agent_name.dates',
      'agent_name_fuller_form' => 'agent_name.fuller_form',
      'agent_name_name_order' => 'agent_name.name_order',
      'agent_name_number' => 'agent_name.number',
      'agent_name_prefix' => 'agent_name.prefix',
      'agent_name_title' => 'agent_name.title',
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

      'subject_source' => 'subject.source',
      'subject_term' => 'subject.term',
      'subject_term_type' => 'subject.term_type',

      # 2. Define data handlers
      #    :record_type of the schema (if other than the handler key)
      #    :defaults - hash which maps property keys to default values if nothing shows up in the source date
      #    :on_row_complete - Proc to run whenever a row in the CSV table is complete
      #        param 1 is the set of objects generated by the row
      #        param 2 is an object in the row (of the type described in the handler)

      :agent => {
        :record_type => Proc.new {|data|
            @agent_type = data['agent_type']
          },
        :on_row_complete => Proc.new {|cache, agent|
            accession = cache.find {|obj| obj.class.record_type == 'accession' }

            if accession
              accession.linked_agents[0]['ref'] = agent.uri
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

      :agent_fax => telephone_template('fax'),

      :agent_telephone => telephone_template('home'),

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

      :accession => {
        :on_create => Proc.new {|data, obj|
          if data['agent_role']
            if data['agent_relator']
              obj.linked_agents << {'role' => data['agent_role'], 'relator' => data['agent_relator']}
            else
              obj.linked_agents << {'role' => data['agent_role']}
            end
          end
        },
        :on_row_complete => Proc.new { |queue, accession|
          queue.select {|obj| obj.class.record_type == 'event'}.each do |event|
            event.linked_records << {'role' => 'source', 'ref' => accession.uri}
          end
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
          accession = cache.find {|obj| obj.class.record_type == 'accession'}
          accession.subjects << {'ref' => this.uri}
        }
      },

      :lang_material => {
        :on_create => Proc.new {|data, obj|
          obj.language_and_script = {'jsonmodel_type' => 'language_and_script', 'language' => data['language'], 'script' => data['script']}
        },
        :on_row_complete => Proc.new {|cache, this|
          accession = cache.find {|obj| obj.class.record_type =~ /^accession/ }
          accession.lang_materials << this
        }
      },

      :date_1 => {
        :record_type => :date,
        :defaults => date_defaults,
        :on_row_complete => Proc.new { |queue, date|
          queue.select {|obj| obj.class.record_type == 'accession'}.each do |accession|
            verify_date_type(date)

            accession.dates << date
          end
        }


      },

      :date_2 => {
        :record_type => :date,
        :defaults => date_defaults,
        :on_row_complete => Proc.new { |queue, date|
          queue.select {|obj| obj.class.record_type == 'accession'}.each do |accession|
            verify_date_type(date)

            accession.dates << date
          end
        }
      },

      :extent => {
        :defaults => {:portion => 'whole'},
        :on_row_complete => Proc.new { |queue, extent|
          queue.select {|obj| obj.class.record_type == 'accession'}.each do |accession|
            accession.extents << extent
          end
        }
      },

      :collection_management => {
        :on_row_complete => Proc.new { |queue, cm|
          queue.select {|obj| obj.class.record_type == 'accession'}.each do |accession|
            accession.collection_management = cm
          end
        }
      },

      :user_defined => {
        :on_row_complete => Proc.new { |queue, user_defined|
          queue.select {|obj| obj.class.record_type == 'accession'}.each do |accession|
            accession.user_defined = user_defined
          end
        }
      },

      :acknowledgement_sent_event => event_template('acknowledgement_sent'),

      :agreement_received_event => event_template('agreement_received'),

      :agreement_sent_event => event_template('agreement_sent'),

      :cataloged_event => event_template('cataloged'),

      :processed_event => event_template('processed'),

    }
  end


  private

  def self.verify_date_type(date)
    date_types = EnumerationValue.filter(
      :enumeration_id => Enumeration.find(:name => 'date_type').values[:id],
      :suppressed => 0,
    ).order(:position).to_a
    .map { |entry| entry.values[:value] }
    .reject { |value| value == 'range' }

    unless date_types.include? date['date_type']
      error_message = "Invalid date type provided: #{date['date_type']}; must be one of: #{date_types}; Date provided: #{date.inspect};"

      raise AccessionConverterInvalidDateTypeError, error_message
    end
  end

  def self.event_template(event_type)
    {
      :record_type => Proc.new {|data|
        data['boolean'] ? :event : nil
      },
      :on_create => Proc.new {|data, obj|
        obj.date = {
                    :jsonmodel_type => 'date',
                    :expression => data['expression'] || 'unknown'
                    }.merge(date_defaults)
        obj.event_type = event_type
        obj.linked_agents = [{'role' => 'executing_program', 'ref' => '/agents/software/1'}]
      }
    }
  end


  def self.telephone_template(type)
    {
      :record_type => Proc.new {|data|
        data['number'] ? :telephone : nil
      },
      :on_create => Proc.new {|data, obj|
        obj.number_type = type
      },
      :on_row_complete => Proc.new {|cache, this|
        agent = cache.find {|obj| obj.class.record_type =~ /^agent_(perso|corpo|famil)/}
        agent.agent_contacts.first['telephones'] << this
      }
    }
  end


  def self.date_defaults
    {
      :label => 'other',
      :date_type => 'inclusive'
    }
  end


  def self.date_flip
    @date_flip ||= Proc.new {|val| val.sub(/^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})$/, '\2/\1/\3')}

    @date_flip
  end

  # need to resue the agent type
  def self.agent_type
    @agent_type ||= "agent_family"
    @agent_type
  end


  def self.normalize_boolean
    @normalize_boolean ||= Proc.new {|val| val.to_s.upcase.match(/\A(1|T|Y|YES|TRUE)\Z/) ? true : false }
    @normalize_boolean
  end
end

class AccessionConverterInvalidDateTypeError < StandardError; end;
