require_relative 'converter'
class AccessionConverter < Converter

  require_relative 'lib/csv_converter'
  include ASpaceImport::CSVConvert

  SUPPORTED_AGENT_TYPES = %w[agent_person agent_family agent_corporate_entity].freeze

  repeatable_record :extent
  repeatable_record :external_document
  repeatable_record :agent, :fields => %w[
    record_id
    role
    relator
    agent_type
    agent_contact_1_address_1
    agent_contact_1_address_2
    agent_contact_1_address_3
    agent_contact_1_city
    agent_contact_1_country
    agent_contact_1_email
    agent_contact_1_fax_1_number
    agent_contact_1_name
    agent_contact_1_post_code
    agent_contact_1_region
    agent_contact_1_salutation
    agent_contact_1_telephone_1_number
    agent_contact_1_telephone_1_ext
    agent_name_1_authority_id
    agent_name_1_dates
    agent_name_1_fuller_form
    agent_name_1_name_order
    agent_name_1_number
    agent_name_1_prefix
    agent_name_1_title
    agent_name_1_primary_name
    agent_name_1_qualifier
    agent_name_1_rest_of_name
    agent_name_1_rules
    agent_name_1_sort_name
    agent_name_1_source
    agent_name_1_subordinate_name_1
    agent_name_1_subordinate_name_2
    agent_name_1_suffix
    note_1_content
    note_1_citation
  ], :parse => false
  repeatable_record :subject, :fields => %w[record_id source term term_type], :parse => false
  repeatable_record :instance, :fields => %w[
    instance_type
    top_container_1_uri
    top_container_1_type
    top_container_1_indicator
    top_container_1_barcode
    top_container_1_container_profile_1_uri
    child_type
    child_indicator
    child_barcode
    grandchild_type
    grandchild_indicator
  ], :parse => false

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
      # 1. Map directly parsed cell data to RecordProxy property paths
      # {column header} => {data address}
      # or,
      # {column header} => [{filter method}, {data address}]
      #
      # Composite repeatable groups declared with :parse => false are assembled in
      # after_row_parsed.

      'accession_title' => 'accession.title',
      'accession_id_1' => 'accession.id_0',
      'accession_id_2' => 'accession.id_1',
      'accession_id_3' => 'accession.id_2',
      'accession_id_4' => 'accession.id_3',
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

      # 2. Define RecordProxy lifecycle handlers for directly parsed records
      #    :record_type - schema type, if different from the handler key
      #    :defaults - properties to set when no value appears in the source data
      #    :on_row_complete - Proc run after the CSV row has been parsed
      #        param 1 is the set of objects generated by the row
      #        param 2 is the object represented by this handler

      :accession => {
        :on_row_complete => Proc.new { |queue, accession|
          queue.select {|obj| obj.class.record_type == 'event'}.each do |event|
            event.linked_records << {'role' => 'source', 'ref' => accession.uri}
          end
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
        :on_row_complete => Proc.new { |queue, extent|
          queue.select {|obj| obj.class.record_type == 'accession'}.each do |accession|
            accession.extents << extent
          end
        }
      },

      :external_document => {
        :on_row_complete => Proc.new { |queue, document|
          queue.select {|obj| obj.class.record_type == 'accession'}.each do |accession|
            accession.external_documents << document
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

  def after_row_parsed(row)
    accession = @batch.working_area.find {|obj| obj.class.record_type == 'accession' }
    if accession
      append_agents(repeatable_row_data('agent', row), accession)
      append_subjects(repeatable_row_data('subject', row), accession)
      append_instances(repeatable_row_data('instance', row), accession)
    end
  end


  def append_agents(agent_groups, accession)
    agent_groups.each do |index, values|
      values = normalize_agent_values(values)
      next if values.values.all? {|value| blank_value?(value) }

      create_values = values.reject {|property, _value| %w[record_id role relator agent_type].include?(property) }.values
      record_id = values['record_id'] unless blank_value?(values['record_id'])
      if record_id && create_values.any? {|value| !blank_value?(value) }
        raise AccessionConverterAgentModeConflictError,
              I18n.t('importer.error.agent_mode_conflict', :index => index)
      end

      if record_id
        accession.linked_agents << agent_relationship(values, agent_uri(index, values['agent_type'], record_id))
      else
        agent = build_agent(index, values)
        accession.linked_agents << agent_relationship(values, agent.uri)
        @batch << agent
      end
    end
  end


  def normalize_agent_values(values)
    values.to_h do |property, value|
      normalized = blank_value?(value) || value == 'NULL' ? nil : value
      if property == 'record_id' && normalized
        normalized = normalize_schema_value(:agent_person, 'uri', normalized)
      end

      [property, normalized]
    end
  end


  def agent_uri(index, agent_type, record_id)
    verify_agent_type(index, agent_type, record_id)

    JSONModel(agent_type.to_sym).uri_for(record_id)
  end


  def verify_agent_type(index, agent_type, record_id = nil)
    return if SUPPORTED_AGENT_TYPES.include?(agent_type)

    if blank_value?(agent_type)
      raise AccessionConverterInvalidAgentTypeError,
            I18n.t('importer.error.missing_agent_type',
                   :index => index,
                   :allowed => SUPPORTED_AGENT_TYPES)
    end

    key = record_id ? 'importer.error.invalid_agent_type_for_link' : 'importer.error.invalid_agent_type'

    raise AccessionConverterInvalidAgentTypeError,
          I18n.t(key,
                 :index => index,
                 :agent_type => agent_type,
                 :record_id => record_id,
                 :allowed => SUPPORTED_AGENT_TYPES)
  end


  def agent_relationship(values, uri)
    relationship = {'ref' => uri}
    relationship['role'] = values['role'] unless blank_value?(values['role'])
    relationship['relator'] = values['relator'] unless blank_value?(values['relator'])
    relationship
  end


  def build_agent(index, values)
    agent_type = values['agent_type']
    verify_agent_type(index, agent_type)

    attributes = agent_creation_attributes(values)
    agent = ASpaceImport::JSONModel(agent_type.to_sym).new
    agent.names = [build_agent_name(agent_type, attributes[:name])]

    contact = build_agent_contact(attributes[:contact], attributes[:telephone], attributes[:fax])
    agent.agent_contacts = [contact] if contact

    note = build_agent_note(attributes[:note])
    agent.notes = [note] if note

    agent
  end


  def build_agent_name(agent_type, values)
    name_type = agent_type.sub(/agent_/, 'name_').to_sym
    name = ASpaceImport::JSONModel(name_type).new
    assign_agent_properties(name, name_type, values)

    if agent_type == 'agent_family' && !blank_value?(values['primary_name'])
      name.family_name = normalize_schema_value(:name_family, 'family_name', values['primary_name'])
    end
    name.sort_name_auto_generate = false unless blank_value?(values['sort_name'])

    name
  end


  def build_agent_contact(contact_values, telephone_values, fax_values)
    values = contact_values.values + telephone_values.values + fax_values.values
    return nil if values.all? {|value| blank_value?(value) }

    contact = ASpaceImport::JSONModel(:agent_contact).new
    assign_agent_properties(contact, :agent_contact, contact_values)
    contact.telephones = [
      build_agent_telephone('fax', fax_values),
      build_agent_telephone('home', telephone_values),
    ].compact

    contact
  end


  def build_agent_telephone(number_type, values)
    return nil if blank_value?(values['number'])

    telephone = {
      'jsonmodel_type' => 'telephone',
      'number_type' => number_type,
      'number' => normalize_schema_value(:telephone, 'number', values['number']),
    }
    unless blank_value?(values['ext'])
      telephone['ext'] = normalize_schema_value(:telephone, 'ext', values['ext'])
    end

    telephone
  end


  def build_agent_note(values)
    content = values['content']
    citation = values['citation']
    return nil if blank_value?(content) && blank_value?(citation)

    subnotes = []
    unless blank_value?(content)
      subnotes << {
        'jsonmodel_type' => 'note_text',
        'content' => normalize_schema_value(:note_text, 'content', content),
      }
    end
    unless blank_value?(citation)
      subnotes << {
        'jsonmodel_type' => 'note_citation',
        'content' => [normalize_schema_value(:note_citation, 'content', citation)],
      }
    end

    ASpaceImport::JSONModel(:note_bioghist).new('subnotes' => subnotes)
  end


  def assign_agent_properties(record, record_type, values)
    schema_properties = record.class.schema['properties']
    values.each do |property, value|
      next if blank_value?(value)
      next unless schema_properties.has_key?(property)

      record.send("#{property}=", normalize_schema_value(record_type, property, value))
    end
  end


  def agent_creation_attributes(values)
    contact = agent_group_values(values, 'agent_contact_1_')
    telephone = {
      'number' => contact.delete('telephone_1_number'),
      'ext' => contact.delete('telephone_1_ext'),
    }
    fax = {'number' => contact.delete('fax_1_number')}

    {
      :name => agent_group_values(values, 'agent_name_1_'),
      :contact => contact,
      :telephone => telephone,
      :fax => fax,
      :note => {
        'content' => values['note_1_content'],
        'citation' => values['note_1_citation'],
      },
    }
  end


  def agent_group_values(values, prefix)
    values.each_with_object({}) do |(property, value), result|
      next unless property.start_with?(prefix)

      result[property.delete_prefix(prefix)] = value
    end
  end


  def blank_value?(value)
    value.nil? || value.to_s.strip.empty?
  end


  def append_subjects(subject_groups, accession)
    subject_groups.each do |index, values|
      values = normalize_subject_values(values)
      next if values.values.all? {|value| blank_value?(value) }

      create_values = values.reject {|property, _value| property == 'record_id' }.values
      record_id = values['record_id'] unless blank_value?(values['record_id'])
      if record_id && create_values.any? {|value| !blank_value?(value) }
        raise AccessionConverterSubjectModeConflictError,
              I18n.t('importer.error.subject_mode_conflict', :index => index)
      end

      if record_id
        accession.subjects << {'ref' => JSONModel(:subject).uri_for(record_id)}
      else
        subject = ASpaceImport::JSONModel(:subject).new
        subject.source = values['source'] unless blank_value?(values['source'])
        subject.terms = [{
          :term => values['term'],
          :term_type => values['term_type'],
          :vocabulary => '/vocabularies/1',
        }]
        subject.vocabulary = '/vocabularies/1'

        accession.subjects << {'ref' => subject.uri}
        @batch << subject
      end
    end
  end


  def normalize_subject_values(values)
    {
      'record_id' => normalize_schema_value(:subject, 'uri', values['record_id']),
      'source' => normalize_schema_value(:subject, 'source', values['source']),
      'term' => normalize_schema_value(:term, 'term', values['term']),
      'term_type' => normalize_schema_value(:term, 'term_type', values['term_type']),
    }
  end


  def append_instances(instance_groups, accession)
    instance_groups.each do |index, values|
      values = normalize_instance_values(values)
      next if values.values.all?(&:nil?)

      top_container_uri = values['top_container_1_uri']
      top_container_creation_values = values.values_at(
        'top_container_1_type',
        'top_container_1_indicator',
        'top_container_1_barcode',
        'top_container_1_container_profile_1_uri',
      )
      if top_container_uri && top_container_creation_values.any?
        raise AccessionConverterTopContainerModeConflictError,
              I18n.t('importer.error.top_container_mode_conflict', :index => index)
      end

      if top_container_uri
        unless top_container_uri.match?(%r{\A/repositories/\d+/top_containers/\d+\z})
          raise AccessionConverterInvalidTopContainerURIError,
                I18n.t('importer.error.invalid_top_container_uri',
                       :index => index, :top_container_uri => top_container_uri)
        end
      else
        top_container = ASpaceImport::JSONModel(:top_container).new
        top_container.type = values['top_container_1_type']
        top_container.indicator = values['top_container_1_indicator']
        top_container.barcode = values['top_container_1_barcode']
        if values['top_container_1_container_profile_1_uri']
          top_container.container_profile = {
            'ref' => values['top_container_1_container_profile_1_uri'],
          }
        end

        top_container_uri = top_container.uri
        @batch << top_container
      end

      sub_container = ASpaceImport::JSONModel(:sub_container).new
      sub_container.top_container = {'ref' => top_container_uri}
      sub_container.type_2 = values['child_type']
      sub_container.indicator_2 = values['child_indicator']
      sub_container.barcode_2 = values['child_barcode']
      sub_container.type_3 = values['grandchild_type']
      sub_container.indicator_3 = values['grandchild_indicator']

      instance = ASpaceImport::JSONModel(:instance).new
      instance.instance_type = values['instance_type']
      instance.sub_container = sub_container
      accession.instances << instance
    end
  end


  def normalize_instance_values(values)
    {
      'instance_type' => normalize_schema_value(:instance, 'instance_type', values['instance_type']),
      'top_container_1_uri' => normalize_schema_value(:top_container, 'uri', values['top_container_1_uri']),
      'top_container_1_type' => normalize_schema_value(:top_container, 'type', values['top_container_1_type']),
      'top_container_1_indicator' => normalize_schema_value(:top_container, 'indicator', values['top_container_1_indicator']),
      'top_container_1_barcode' => normalize_schema_value(:top_container, 'barcode', values['top_container_1_barcode']),
      'top_container_1_container_profile_1_uri' => normalize_schema_value(:container_profile, 'uri', values['top_container_1_container_profile_1_uri']),
      'child_type' => normalize_schema_value(:sub_container, 'type_2', values['child_type']),
      'child_indicator' => normalize_schema_value(:sub_container, 'indicator_2', values['child_indicator']),
      'child_barcode' => normalize_schema_value(:sub_container, 'barcode_2', values['child_barcode']),
      'grandchild_type' => normalize_schema_value(:sub_container, 'type_3', values['grandchild_type']),
      'grandchild_indicator' => normalize_schema_value(:sub_container, 'indicator_3', values['grandchild_indicator']),
    }
  end

  def self.verify_date_type(date)
    date_types = EnumerationValue.filter(
      :enumeration_id => Enumeration.find(:name => 'date_type').values[:id],
      :suppressed => 0,
    ).order(:position).to_a
    .map { |entry| entry.values[:value] }
    .reject { |value| value == 'range' }

    unless date_types.include? date['date_type']
      error_message = I18n.t('importer.error.invalid_date_type',
                             :date_type => date['date_type'],
                             :allowed => date_types,
                             :date => date.inspect)

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

  def self.normalize_boolean
    @normalize_boolean ||= Proc.new {|val| val.to_s.upcase.match(/\A(1|T|Y|YES|TRUE)\Z/) ? true : false }
    @normalize_boolean
  end
end

class AccessionConverterError < StandardError; end;
class AccessionConverterInvalidDateTypeError < AccessionConverterError; end;
class AccessionConverterAgentModeConflictError < AccessionConverterError; end;
class AccessionConverterSubjectModeConflictError < AccessionConverterError; end;
class AccessionConverterInvalidAgentTypeError < AccessionConverterError; end;
class AccessionConverterInvalidTopContainerURIError < AccessionConverterError; end;
class AccessionConverterTopContainerModeConflictError < AccessionConverterError; end;
