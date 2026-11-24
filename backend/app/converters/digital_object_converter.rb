require_relative 'converter'
require_relative '../lib/event_builder'

class DigitalObjectConverter < Converter

  require_relative 'lib/csv_converter'
  include ASpaceImport::CSVConvert

  repeatable_record :event, :parse => false, :fields => CSV.foreach(
    File.join(__dir__, '..', 'lib', 'templates', 'aspace_digital_object_import_template.csv')
  ).first.filter_map { |code| code.to_s.strip[/\Aevent_1_(.+)\z/, 1] }


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

    }
  end


  def self.configure_cell_handlers(row)
    @headers = row.map { |s| s ||= ""; s.strip }

    dups = @headers.select { |h| h.match(/^file_version_/) }
                   .tally
                   .select { |_, count| count > 1 }
                   .keys
    raise ASpaceImport::CSVConvert::CSVSyntaxException.new(:duplicate_file_version_headers, dups) unless dups.empty?

    cell_handlers, bad_headers = super
    bad_headers.reject! do |header|
      file_version_header?(header) ||
        %w[
          agent_name_description_type
          digital_object_rights_transferred
          digital_object_rights_transferred_date
          digital_object_rights_transferred_note
        ].include?(header)
    end
    [cell_handlers, bad_headers]
  end


  def self.headers
    @headers
  end


  def self.file_version_header?(header)
    match = header.match(/\Afile_version_([a-z_]+?)(_\d+)?\z/)
    return false unless match

    ASpaceImport::JSONModel(:file_version).schema['properties'].reject { |_name, defn| defn['readonly'] }.key?(match[1])
  end


  private

  def after_row_parsed(row)
    row_hash = Hash[self.class.headers.zip(row)]
    digital_object = @batch.working_area.find { |obj| obj.class.record_type =~ /^digital_object/ }
    append_file_versions(row_hash, digital_object) if digital_object
    append_events(repeatable_row_data('event', row), digital_object)
  end


  def append_file_versions(row_hash, digital_object)
    file_version_suffixes(row_hash).each do |suffix|
      uri = normalized_file_version_value('file_uri', suffix, row_hash)
      next if uri.nil? || uri.empty?

      fv = ASpaceImport::JSONModel(:file_version).new
      fv.file_uri = uri

      file_version_properties.each do |property|
        next if property == 'file_uri'

        value = normalized_file_version_value(property, suffix, row_hash)
        fv.send("#{property}=", value) unless value.nil?
      end

      digital_object.file_versions << fv
    end
  end


  def normalized_file_version_value(property, suffix, row_hash)
    raw = row_hash["file_version_#{property}#{suffix}"]
    return nil if raw.nil? || raw == 'NULL'

    property_def = ASpaceImport::JSONModel(:file_version).schema['properties'][property]
    filter_type = ASpaceImport::Utils.get_property_type(property_def)[0]

    raw = self.class.normalize_boolean.call(raw) if filter_type == :boolean

    ASpaceImport::Utils.value_filter(filter_type).call(raw)
  end


  def file_version_suffixes(row_hash)
    row_hash.keys
      .grep(/^file_version_file_uri(_\d+)?$/)
      .sort_by { |key| key[/\d+/].to_i }
      .map { |key| key[/_\d+$/] || "" }
  end


  def file_version_properties
    ASpaceImport::JSONModel(:file_version).schema['properties'].reject do |_name, defn|
      defn['readonly']
    end.keys
  end


  def append_events(event_groups, record)
    event_groups.each do |index, values|
      values = values.transform_values { |value| value.to_s.strip.empty? ? nil : value.strip }
      next if values.values.all?(&:nil?)

      unless record && record.class.record_type == 'digital_object'
        raise DigitalObjectConverterEventError,
              I18n.t('importer.error.event_without_digital_object', :index => index)
      end

      builder = EventBuilder.new(
        :attributes => values.transform_keys { |leaf| event_attribute(leaf) },
        :controlled_value_resolver => method(:controlled_value)
      )
      unless builder.errors.empty?
        raise DigitalObjectConverterEventError,
              builder.errors.map { |error| event_error_message(index, error) }.join("\n")
      end

      @batch << ASpaceImport::JSONModel(:event).new(
        builder.to_h(:source_uri => record.uri, :system_agent_ref => system_agent_ref)
      )
    end
  end


  def event_attribute(leaf)
    return :event_type if leaf == 'type'
    return :date if leaf == 'date_begin'

    leaf.sub(/\Aagent_1_(agent_)?/, 'agent_').to_sym
  end


  def event_field(index, attribute)
    leaf = self.class.repeatable_record_definitions['event'][:fields].find do |candidate|
      event_attribute(candidate) == attribute
    end
    "event_#{index}_#{leaf}"
  end


  def event_error_message(index, error)
    params = {
      :index => index,
      :field => event_field(index, error[:attribute]),
      :value => error[:value],
      :begin_field => event_field(index, :date),
      :expression_field => event_field(index, :date_expression),
    }

    case error[:code]
    when :required
      key = error[:attribute] == :date ? 'event_date_required' : 'event_required_field'
      I18n.t("importer.error.#{key}", **params)
    when :requires_date
      I18n.t('importer.error.event_field_requires_date', **params)
    when :forbidden
      I18n.t('importer.error.event_agent_type_with_uri',
             **params, :record_field => event_field(index, :agent_record_id))
    when :unsupported
      I18n.t('importer.error.event_agent_unsupported_type',
             **params, :accepted => EventBuilder.agent_types.join(', '))
    when :invalid
      I18n.t("importer.error.#{invalid_event_value_key(error[:attribute])}", **params)
    else
      raise KeyError, "Unhandled EventBuilder error code: #{error[:code]}"
    end
  end


  def invalid_event_value_key(attribute)
    case attribute
    when :date then 'event_invalid_date_begin'
    when :agent_record_id then 'event_invalid_agent_record_id'
    else 'event_invalid_controlled_value'
    end
  end


  def controlled_value(list_name, value)
    @controlled_value_lists ||= {}
    @controlled_value_lists[list_name] ||= CvList.new(
      list_name, User.find(:username => RequestContext.get(:current_username))
    )
    @controlled_value_lists[list_name].lookup(value)
  end


  def system_agent_ref
    @system_agent_ref ||= AgentSoftware.archivesspace_record.uri
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

class DigitalObjectConverterError < StandardError; end;
class DigitalObjectConverterEventError < DigitalObjectConverterError; end;
