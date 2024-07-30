class BulkArchivalObjectUpdater
  attr_reader :filename, :parameters, :errors, :info_messages, :updated_uris

  BATCH_SIZE = 128

  SUBRECORD_DEFAULTS = {
    'dates' => {
      'label' => 'creation',
    },
    'instance' => {
      'jsonmodel_type' => 'instance',
      'sub_container' => {
        'jsonmodel_type' => 'sub_container',
        'top_container' => {'ref' => nil},
      }
    },
    'note_multipart' => {
      'jsonmodel_type' => 'note_multipart',
      'subnotes' => [],
    },
    'note_singlepart' => {
      'jsonmodel_type' => 'note_singlepart',
      'content' => [],
    },
  }

  INSTANCE_FIELD_MAPPINGS = [
    ['instance_type', 'instance_type'],
  ]

  SUB_CONTAINER_FIELD_MAPPINGS = [
    ['type_2', 'sub_container_type_2'],
    ['indicator_2', 'sub_container_indicator_2'],
    ['barcode_2', 'sub_container_barcode_2'],
    ['type_3', 'sub_container_type_3'],
    ['indicator_3', 'sub_container_indicator_3']
  ]

  def initialize(filename, parameters)
    @filename = filename
    @parameters = parameters
    @errors = []
    @info_messages = []
    @updated_uris = []
  end

  def run
    check_sheet(filename)

    column_by_path = extract_columns(filename)

    subrecord_columns = find_subrecord_columns(column_by_path)

    DB.open(true) do |db|
      resource_id = resource_ids_in_play(filename).fetch(0)

      @top_containers_in_resource = subrecord_columns[:top_container] ? extract_top_containers_for_resource(db, resource_id) : {}

      if SpreadsheetBuilder.related_accessions_enabled?
        @accessions_in_sheet = subrecord_columns[:related_accession] ? extract_accessions_from_sheet(db, filename, subrecord_columns[:related_accession]) : {}
      end

      if create_missing_top_containers? && subrecord_columns[:top_container]
        top_containers_in_sheet = extract_top_containers_from_sheet(filename, subrecord_columns[:top_container])
        create_missing_top_containers(top_containers_in_sheet)
      end

      if subrecord_columns[:digital_object]
        digital_objects_in_sheet = extract_digital_objects_from_sheet(filename, subrecord_columns[:digital_object])
        @digital_object_id_to_uri_map = apply_digital_objects_changes(digital_objects_in_sheet, db)
      end

      batch_rows(filename) do |batch|
        to_process = batch.map {|row| [Integer(row.fetch('id')), row]}.to_h

        ao_objs = ArchivalObject.filter(:id => to_process.keys).all
        ao_jsons = ArchivalObject.sequel_to_jsonmodel(ao_objs)

        ao_objs.zip(ao_jsons).each do |ao, ao_json|
          process_row(to_process.fetch(ao.id), ao, ao_json, column_by_path, subrecord_columns)
        end
      end

      if errors.length > 0
        raise BulkUpdateFailed.new(errors)
      end
    end

    {
      updated_uris: updated_uris
    }
  end

  def apply_deletes?
    AppConfig.has_key?(:bulk_archival_object_updater_apply_deletes) && AppConfig[:bulk_archival_object_updater_apply_deletes] == true
  end

  def create_missing_top_containers?
    if parameters.has_key?(:create_missing_top_containers)
      parameters[:create_missing_top_containers]
    elsif AppConfig.has_key?(:bulk_archival_object_updater_create_missing_top_containers)
      AppConfig[:bulk_archival_object_updater_create_missing_top_containers]
    else
      false
    end
  end

  private

  def process_row(row, ao, ao_json, column_by_path, subrecord_columns)
    record_changed = false

    subrecord_updates_by_index = {}
    instance_updates_by_index = {}
    digital_object_updates_by_index = {}
    related_accession_updates_by_index = {}
    lang_material_updates_by_index = {:language_and_script => {}, :note_langmaterial => {}}

    notes_by_type = {}

    begin
      row.values.each do |path, value|
        column = column_by_path.fetch(path)

        next unless subrecord_columns[column.jsonmodel]

        # fields on the AO
        if column.jsonmodel == :archival_object
          record_changed = apply_archival_object_column(row, column, path, value, ao_json) || record_changed

          # notes
        elsif path.start_with?('note/')
          if path =~ /note\/([a-z_-]+)\/.*/
            note_type = $1
            note_jsonmodel = SpreadsheetBuilder.note_jsonmodel_for_type(note_type)

            record_changed = apply_notes_column(row, column, value, ao_json, notes_by_type, note_jsonmodel, note_type) || record_changed
          else
            raise "note column path doesn't comply with note/{note_type}/{field}: #{path}"
          end

          # subrecords
        elsif SpreadsheetBuilder::SUBRECORDS_OF_INTEREST.include?(column.jsonmodel)
          subrecord_updates_by_index[column.property_name] ||= {}

          clean_value = column.sanitise_incoming_value(value)

          subrecord_updates_by_index[column.property_name][column.index] ||= {}
          subrecord_updates_by_index[column.property_name][column.index][column.name.to_s] = clean_value

          # instances
        elsif column.jsonmodel == :instance
          instance_updates_by_index[column.index] ||= {}

          clean_value = column.sanitise_incoming_value(value)

          instance_updates_by_index[column.index][column.name.to_s] = clean_value

        # digital objects
        elsif column.jsonmodel == :digital_object
          digital_object_updates_by_index[column.index] ||= {}

          clean_value = column.sanitise_incoming_value(value)

          digital_object_updates_by_index[column.index][column.name.to_s] = clean_value

        # related accessions
        elsif column.jsonmodel == :related_accession
          related_accession_updates_by_index[column.index] ||= {}
          related_accession_updates_by_index[column.index][column.name.to_s] = column.sanitise_incoming_value(value)

        elsif column.jsonmodel == :language_and_script
          lang_material_updates_by_index[:language_and_script][column.index] ||= {}
          lang_material_updates_by_index[:language_and_script][column.index][column.name.to_s] = column.sanitise_incoming_value(value)

        elsif column.jsonmodel == :note_langmaterial
          lang_material_updates_by_index[:note_langmaterial][column.index] ||= {}
          lang_material_updates_by_index[:note_langmaterial][column.index] = column.sanitise_incoming_value(value)

        else
          Log.error("Not able to handle column: #{column.path}")
        end
      end

      record_changed = apply_sub_record_updates(row, ao_json, subrecord_updates_by_index) || record_changed

      unless instance_updates_by_index.empty? && digital_object_updates_by_index.empty?
        record_changed = apply_instance_updates(row, ao_json, instance_updates_by_index, digital_object_updates_by_index) || record_changed
      end

      if SpreadsheetBuilder.related_accessions_enabled?
        record_changed = apply_related_accession_updates(row, ao_json, related_accession_updates_by_index) || record_changed
      end

      record_changed = apply_lang_material_updates(row, ao_json, lang_material_updates_by_index) || record_changed

      if apply_deletes?
        record_changed = delete_empty_notes(ao_json) || record_changed
      end

      # Apply changes to the Archival Object!
      if record_changed
        ao_json['position'] = nil
        ao.update_from_json(ao_json)

        info_messages.push("Updated archival object #{ao.id} - #{ao_json.display_string}")

        updated_uris << ao_json['uri']
      end

    rescue ArgumentError => arg_error
      if arg_error.message == 'invalid date'
        errors << {
          sheet: SpreadsheetBuilder::SHEET_NAME,
          json_property: 'N/A',
          row: row.row_number,
          errors: ['Invalid date detected'],
        }
      else
        raise arg_error
      end

    rescue JSONModel::ValidationException => validation_errors
      validation_errors.errors.each do |json_property, messages|
        errors << {
          sheet: SpreadsheetBuilder::SHEET_NAME,
          json_property: json_property,
          row: row.row_number,
          errors: messages,
        }
      end
    end
  end

  def apply_archival_object_column(row, column, path, value, ao_json)
    record_changed = false

    # we don't change the id!
    return record_changed if column.name == :id

    # Validate the lock_version
    if column.name == :lock_version
      if Integer(value) != ao_json['lock_version']
        errors << {
          sheet: SpreadsheetBuilder::SHEET_NAME,
          column: column.path,
          row: row.row_number,
          errors: ["Versions are out of sync: #{value} record is now: #{ao_json['lock_version']}"]
        }
      end
    else
      clean_value = column.sanitise_incoming_value(value)

      # component_id is tricky as it has a default value of "", so we need to
      # assume nil is actually "".
      if path == 'component_id' && clean_value.nil?
        clean_value = ''
      end

      if ao_json[path] != clean_value
        record_changed = true
        ao_json[path] = clean_value
      end
    end

    record_changed
  end

  def apply_notes_column(row, column, value, ao_json, notes_by_type, note_jsonmodel, note_type)
    record_changed = false

    unless notes_by_type.has_key?(note_type)
      notes_by_type[note_type] = ao_json.notes
                                   .select {|note| note['jsonmodel_type'] == note_jsonmodel.to_s && note['type'] == note_type.to_s}
    end

    clean_value = column.sanitise_incoming_value(value)

    note_to_update = notes_by_type[note_type].fetch(column.index, nil)

    if note_to_update.nil? && !clean_value.to_s.empty?
      # we need to create a new note!
      record_changed = true

      note_to_update = default_record_values(note_jsonmodel).merge('type' => note_type.to_s)

      notes_by_type[note_type][column.index] = note_to_update
      ao_json.notes << note_to_update
    end

    if note_to_update
      # Apply content
      if column.is_a?(SpreadsheetBuilder::NoteContentColumn)
        first_text_note = column.multipart? ?
                            note_to_update['subnotes'].detect {|subnote| subnote['jsonmodel_type'] == 'note_text'} :
                            note_to_update['content'].first

        if first_text_note
          current_note_value = column.multipart? ? first_text_note['content'] : first_text_note
          if clean_value != current_note_value
            record_changed = true

            if clean_value.to_s.empty? && !apply_deletes?
              errors << {
                sheet: SpreadsheetBuilder::SHEET_NAME,
                column: column.path,
                row: row.row_number,
                errors: ["Deleting a note is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."],
              }
            else
              if column.multipart?
                first_text_note['content'] = clean_value
              else
                note_to_update['content'][0] = clean_value
              end
            end
          end

            # Add a text note!
        elsif !clean_value.to_s.empty?
          record_changed = true

          if column.multipart?
            note_to_update['subnotes'] << default_record_values('note_text').merge({
                                                                                    'jsonmodel_type' => 'note_text',
                                                                                    'content' => clean_value
                                                                                   })
          else
            note_to_update['content'] << clean_value
          end
        end

      # Update the extra note field
      else
        note_path_to_update = nil
        if column.property_name.to_s == 'note'
          note_path_to_update = note_to_update
        else
          # column property name gives the path to a nested record on the note
          note_to_update[column.property_name.to_s] ||= {}
          note_path_to_update = note_to_update[column.property_name.to_s]
        end

        if column.name.to_s == 'local_access_restriction_type'
          # this is an array!
          clean_value = clean_value.to_s.empty? ? [] : [clean_value]
        end

        if note_path_to_update[column.name.to_s] != clean_value
          record_changed = true
          note_path_to_update[column.name.to_s] = clean_value
        end
      end
    end

    record_changed
  end

  def default_record_values(jsonmodel_type)
    return {} unless SUBRECORD_DEFAULTS.has_key?(jsonmodel_type.to_s)

    Marshal.load(Marshal.dump(SUBRECORD_DEFAULTS.fetch(jsonmodel_type.to_s)))
  end

  def apply_sub_record_updates(row, ao_json, subrecord_updates_by_index)
    record_changed = false

    # apply subrecords to the json
    #  - update existing
    #  - add new subrecords
    #  - those not updated are deleted
    subrecord_updates_by_index.each do |jsonmodel_property, updates_by_index|
      subrecords_to_apply = []

      updates_by_index.each do |index, subrecord_updates|
        if (existing_subrecord = Array(ao_json[jsonmodel_property.to_s])[index])
          if subrecord_updates.all? {|_, value| value.to_s.empty? }
            if apply_deletes?
              # DELETE!
              record_changed = true
              next
            else
              errors << {
                sheet: SpreadsheetBuilder::SHEET_NAME,
                column: "#{jsonmodel_property}/#{index}",
                row: row.row_number,
                errors: ["Deleting a subrecord is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."],
              }
            end
          end

          if subrecord_updates.any? {|property, value| existing_subrecord[property] != value}
            record_changed = true

            if jsonmodel_property.to_s == 'dates'
              apply_date_defaults(subrecord_updates)
            end
          end

          subrecords_to_apply << existing_subrecord.merge(subrecord_updates)
        else
          if subrecord_updates.values.all? {|v| v.to_s.empty? }
            # Nothing to do!
            next
          end

          if jsonmodel_property.to_s == 'dates'
            apply_date_defaults(subrecord_updates)
          end

          record_changed = true
          subrecord_to_create = default_record_values(jsonmodel_property).merge(subrecord_updates)

          subrecords_to_apply << subrecord_to_create
        end
      end

      ao_json[jsonmodel_property.to_s] = subrecords_to_apply
    end

    record_changed
  end

  def delete_empty_notes(ao_json)
    record_changed = false

    # drop any multipart notes with only empty sub notes
    # - drop subnotes empty note_text
    ao_json.notes.each do |note|
      if note['jsonmodel_type'] == 'note_multipart'
        note['subnotes'].reject! do |subnote|
          if subnote['jsonmodel_type'] == 'note_text' && subnote['content'].to_s.empty?
            record_changed = true
            true
          else
            false
          end
        end
      end
    end
    # - drop notes with empty subnotes
    ao_json.notes.reject! do |note|
      if note['jsonmodel_type'] == 'note_multipart' && note['subnotes'].empty?
        record_changed = true
        true
      else
        false
      end
    end

    record_changed
  end

  def apply_lang_material_updates(row, ao_json, lang_material_updates_by_index)
    record_changed = false

    existing_language_and_script = ao_json.lang_materials.select {|lm| lm['language_and_script'] && ASUtils.wrap(lm['notes']).empty?}

    language_and_script_to_apply = []

    lang_material_updates_by_index[:language_and_script].each do |index, updates|
      if (existing_subrecord = existing_language_and_script.fetch(index, false))
        if updates.all? {|_, value| value.to_s.empty? }
          if apply_deletes?
            # DELETE!
            record_changed = true
          else
            errors << {
              sheet: SpreadsheetBuilder::SHEET_NAME,
              column: "language_and_script/#{index}",
              row: row.row_number,
              errors: ["Deleting a Language is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."],
            }
          end

          next
        end

        if updates.all? {|field, value| existing_subrecord.fetch('language_and_script')[field].to_s == value.to_s}
          # no changes
          language_and_script_to_apply << existing_subrecord
          next
        end

        record_changed = true

        existing_subrecord['language_and_script'] = existing_subrecord.fetch('language_and_script').merge(updates)

        language_and_script_to_apply << existing_subrecord
      elsif updates.any? {|_, value| !value.to_s.strip.empty?}
        record_changed = true

        language_and_script_to_apply << {
          'jsonmodel' => 'lang_material',
          'language_and_script' => {
            'jsonmodel_type' => 'language_and_script',
          }.merge(updates)
        }
      end
    end

    # All langmaterial notes flattened (we only update the first `content` from each)
    existing_note_langmaterial = ao_json.lang_materials.select {|lm| !ASUtils.wrap(lm['notes']).empty?}
    existing_note_langmaterial_content = existing_note_langmaterial.map {|lm| lm['notes']}.flatten
    notes_to_create = []

    lang_material_updates_by_index[:note_langmaterial].each do |index, value_from_spreadsheet|
      note_to_update = existing_note_langmaterial_content.fetch(index, nil)

      if (note_to_update = existing_note_langmaterial_content.fetch(index, false))
        if note_to_update.dig('content', 0) == value_from_spreadsheet
          # nothing to do...
          next
        end

        record_changed = true

        if value_from_spreadsheet.to_s.empty? && !apply_deletes?
          errors << {
            sheet: SpreadsheetBuilder::SHEET_NAME,
            column: column.path,
            row: row.row_number,
            errors: ["Deleting a Language Note is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."],
          }
        end

        note_to_update['content'][0] = value_from_spreadsheet
      elsif !value_from_spreadsheet.to_s.empty?
        # Add a text note!
        record_changed = true

        notes_to_create << {
          'jsonmodel' => 'lang_material',
          'notes' => [{
                        'content' => [value_from_spreadsheet],
                        'jsonmodel_type' => 'note_langmaterial',
                        'type' => 'langmaterial',
                      }]
        }
      end
    end

    if apply_deletes?
      # drop any language and script where both are empty
      language_and_script_to_apply.reject! do |lm|
        lm.fetch('language_and_script')['language'].to_s.empty? && lm.fetch('language_and_script')['script'].to_s.empty?
      end

      # drop any notes where the content has been nil'd out and there are no
      # other content strings on the note
      existing_note_langmaterial.reject! do |lm|
        lm['notes'].each do |note|
          note['content'].reject! {|s| s.to_s.empty?}
        end

        lm['notes'].reject! {|note| note['content'].empty?}

        lm['notes'].empty?
      end
    end

    if record_changed
      ao_json.lang_materials = language_and_script_to_apply + existing_note_langmaterial + notes_to_create
    end

    record_changed
  end


  def apply_related_accession_updates(row, ao_json, related_accession_updates_by_index)
    record_changed = false

    to_apply = []
    related_accessions_changed = false

    related_accession_updates_by_index.each do |index, updates|
      related_accession_changed = false

      # the accession
      candidate = AccessionCandidate.new(updates['id_0'],
                                         updates['id_1'],
                                         updates['id_2'],
                                         updates['id_3'])

      if (existing_subrecord = ao_json.accession_links.fetch(index, false))
        replacement_subrecord = {}

        if updates.all? {|_, value| value.to_s.empty? }
          if apply_deletes?
            # DELETE!
            record_changed = true
            related_accessions_changed = true
          else
            errors << {
              sheet: SpreadsheetBuilder::SHEET_NAME,
              column: "related_accessions/#{index}",
              row: row.row_number,
              errors: ["Deleting a related accession is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."],
            }
          end

          next
        end

        if candidate.empty?
          # assume this was intentional and let validation do its thing
          replacement_subrecord['ref'] = nil
        else
          if (accession_uri = @accessions_in_sheet[candidate])
            if existing_subrecord.fetch('ref') != accession_uri
              replacement_subrecord['ref'] = accession_uri
              related_accession_changed = true
            end
          else
            errors << {
              sheet: SpreadsheetBuilder::SHEET_NAME,
              column: "related_accessions/#{index}/id_0",
              row: row.row_number,
              errors: ["Accession not found for identifier: #{candidate.inspect}"],
            }
          end
        end

        # did anything change?
        if related_accession_changed
          record_changed = true
          related_accessions_changed = true
        end

        # ready to apply
        to_apply << replacement_subrecord
      else
        if updates.values.all? {|v| v.to_s.empty? }
          # Nothing to do!
          next
        end

        record_changed = true
        related_accessions_changed = true

        to_create = {}

        if (accession_uri = @accessions_in_sheet[candidate])
          to_create['ref'] = accession_uri
        else
          errors << {
            sheet: SpreadsheetBuilder::SHEET_NAME,
            column: "related_accessions/#{index}/id_0",
            row: row.row_number,
            errors: ["Accession not found for identifier: #{candidate.inspect}"],
          }
        end

        to_apply << to_create
      end
    end

    if related_accessions_changed
      ao_json.accession_links = to_apply
    end

    record_changed
  end

  def apply_instance_updates(row, ao_json, instance_updates_by_index, digital_object_updates_by_index)
    record_changed = false

    last_used_index = ao_json.instances.length

    # store something to help retain instance sort order
    ao_json.instances.each_with_index do |instance, index|
      instance['_sort_'] = index
    end

    # handle instance updates
    existing_sub_container_instances = ao_json.instances.select {|instance| instance['instance_type'] != 'digital_object'}
    existing_digital_object_instances = ao_json.instances.select {|instance| instance['instance_type'] == 'digital_object'}
    instances_to_apply = []
    instances_changed = false

    if instance_updates_by_index.empty?
      # no changes, so keep the existing instances please
      instances_to_apply = existing_sub_container_instances
    else
      instance_updates_by_index.each do |index, instance_updates|
        if (existing_subrecord = existing_sub_container_instances.fetch(index, false))
          if instance_updates.all? {|_, value| value.to_s.empty? }
            if apply_deletes?
              # DELETE!
              record_changed = true
              instances_changed = true
            else
              errors << {
                sheet: SpreadsheetBuilder::SHEET_NAME,
                column: "instances/#{index}",
                row: row.row_number,
                errors: ["Deleting an instance is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."],
              }
            end

            next
          end

          instance_changed = false

          # instance fields
          INSTANCE_FIELD_MAPPINGS.each do |instance_field, spreadsheet_field|
            if existing_subrecord[instance_field] != instance_updates[spreadsheet_field]
              instance_changed = true
              existing_subrecord[instance_field] = instance_updates[spreadsheet_field]
            end
          end

          # sub_container fields
          SUB_CONTAINER_FIELD_MAPPINGS.each do |sub_container_field, spreadsheet_field|
            if existing_subrecord.fetch('sub_container')[sub_container_field] != instance_updates[spreadsheet_field]
              existing_subrecord.fetch('sub_container')[sub_container_field] = instance_updates[spreadsheet_field]
              instance_changed = true
            end
          end

          # the top container
          candidate_top_container = TopContainerCandidate.new(instance_updates['top_container_type'],
                                                              instance_updates['top_container_indicator'],
                                                              instance_updates['top_container_barcode'])

          if candidate_top_container.empty?
            # assume this was intentional and let validation do its thing
            existing_subrecord['sub_container']['top_container']['ref'] = nil
          else
            if @top_containers_in_resource.has_key?(candidate_top_container)
              top_container_uri = @top_containers_in_resource.fetch(candidate_top_container)

              if existing_subrecord.fetch('sub_container').fetch('top_container').fetch('ref') != top_container_uri
                existing_subrecord['sub_container']['top_container']['ref'] = top_container_uri
                instance_changed = true
              end
            else
              errors << {
                sheet: SpreadsheetBuilder::SHEET_NAME,
                column: "instances/#{index}/top_container_indicator",
                row: row.row_number,
                errors: [missing_top_container_error_message(candidate_top_container, @top_containers_in_resource)],
              }
            end
          end

          # did anything change?
          if instance_changed
            record_changed = true
            instances_changed = true
          end

          # ready to apply
          instances_to_apply << existing_subrecord
        else
          if instance_updates.values.all? {|v| v.to_s.empty? }
            # Nothing to do!
            next
          end

          record_changed = true
          instances_changed = true

          instance_to_create = default_record_values('instance').merge(
            INSTANCE_FIELD_MAPPINGS.map {|target_field, spreadsheet_field| [target_field, instance_updates[spreadsheet_field]]}.to_h
          )

          last_used_index += 1
          instance_to_create['_sort_'] = last_used_index

          instance_to_create['sub_container'].merge!(
            SUB_CONTAINER_FIELD_MAPPINGS.map {|target_field, spreadsheet_field| [target_field, instance_updates[spreadsheet_field]]}.to_h
          )

          candidate_top_container = TopContainerCandidate.new(instance_updates['top_container_type'],
                                                              instance_updates['top_container_indicator'],
                                                              instance_updates['top_container_barcode'])

          if @top_containers_in_resource.has_key?(candidate_top_container)
            top_container_uri = @top_containers_in_resource.fetch(candidate_top_container)
            instance_to_create['sub_container']['top_container'] = {'ref' => top_container_uri}
          else
            errors << {
              sheet: SpreadsheetBuilder::SHEET_NAME,
              column: "instances/#{index}/top_container_indicator",
              row: row.row_number,
              errors: [missing_top_container_error_message(candidate_top_container, @top_containers_in_resource)],
            }
          end

          instances_to_apply << instance_to_create
        end
      end
    end

    digital_object_instances_to_apply = []

    if digital_object_updates_by_index.empty?
      # no changes, so keep the existing instances please
      digital_object_instances_to_apply = existing_digital_object_instances
    else
      digital_object_updates_by_index.each do |index, digital_object_updates|
        digital_object_id = digital_object_updates['digital_object_id']

        if (existing_subrecord = existing_digital_object_instances.fetch(index, false))
          if digital_object_updates.all? {|_, value| value.to_s.empty? }
            if apply_deletes?
              # DELETE!
              record_changed = true
              instances_changed = true
            else
              errors << {
                sheet: SpreadsheetBuilder::SHEET_NAME,
                column: "instances/#{index}",
                row: row.row_number,
                errors: ["Deleting an digital object instance is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."],
              }
            end

            next
          end

          if digital_object_id.to_s.empty?
            errors << {
              sheet: SpreadsheetBuilder::SHEET_NAME,
              column: "digital_object/#{index}/digital_object_id",
              row: row.row_number,
              errors: ["Digital Object ID is required"],
            }

            next
          else
            if @digital_object_id_to_uri_map.has_key?(digital_object_id)
              digital_object_uri = @digital_object_id_to_uri_map.fetch(digital_object_id).fetch(:uri)

              if existing_subrecord.fetch('digital_object').fetch('ref') != digital_object_uri
                existing_subrecord['digital_object']['ref'] = digital_object_uri
                instance_changed = true
              end
            else
              errors << {
                sheet: SpreadsheetBuilder::SHEET_NAME,
                column: "digital_object/#{index}/digital_object_id",
                row: row.row_number,
                errors: ["Digital Object not found for #{digital_object_id}"],
              }
            end
          end

          # did anything change?
          if instance_changed
            record_changed = true
            instances_changed = true
          end

          # ready to apply
          digital_object_instances_to_apply << existing_subrecord
        else
          if digital_object_updates.values.all? {|v| v.to_s.empty? }
            # Nothing to do!
            next
          end

          record_changed = true
          instances_changed = true

          if @digital_object_id_to_uri_map.has_key?(digital_object_id)
            instance_to_create = {
              'jsonmodel_type' => 'instance',
              'instance_type' => 'digital_object',
              'digital_object' => {
                'ref' => @digital_object_id_to_uri_map.fetch(digital_object_id).fetch(:uri)
              }
            }

            last_used_index += 1
            instance_to_create['_sort_'] = last_used_index

            digital_object_instances_to_apply << instance_to_create
          else
            errors << {
              sheet: SpreadsheetBuilder::SHEET_NAME,
              column: "digital_object/#{index}/digital_object_id",
              row: row.row_number,
              errors: ["Digital Object not found for #{digital_object_id}"],
            }
          end
        end
      end
    end

    if instances_changed
      ao_json.instances = (instances_to_apply + digital_object_instances_to_apply).sort_by {|instance| instance['_sort_']}.map {|instance| instance.delete('_sort_'); instance}
    end

    record_changed
  end

  def apply_date_defaults(subrecord)
    if subrecord['end'].nil?
      subrecord['date_type'] = 'single'
    else
      subrecord['date_type'] = 'inclusive'
    end

    subrecord
  end

  def extract_columns(filename)
    path_row = nil

    XLSXStreamingReader.new(filename).each(SpreadsheetBuilder::SHEET_NAME).each_with_index do |row, idx|
      next if idx == 0
      path_row = row_values(row)
      break
    end

    raise "Missing header row containing paths in #{filename}" if path_row.nil?

    path_row.map do |path|
      column = SpreadsheetBuilder.column_for_path(path)
      raise "Missing column definition for path: #{path}" if column.nil?

      [path, column]
    end.to_h
  end

  def extract_ao_ids(filename)
    result = []
    each_row(filename) do |row|
      result << Integer(row.fetch('id'))
    end
    result
  end

  TopContainerCandidate = Struct.new(:top_container_type, :top_container_indicator, :top_container_barcode) do
    def empty?
      top_container_type.nil? && top_container_indicator.nil? && top_container_barcode.nil?
    end

    def to_s
      "#<BulkArchivalObjectUpdater::TopContainerCandidate #{self.to_h.inspect}>"
    end

    def inspect
      to_s
    end
  end

  DigitalObjectCandidate = Struct.new(:digital_object_id, :digital_object_title, :digital_object_publish, :file_version_file_uri, :file_version_caption, :file_version_publish) do
    def empty?
      members.all? {|attr| self[attr].to_s.empty?}
    end

    def link_only?
      !self.digital_object_id.to_s.empty? && (members - [:digital_object_id]).all? {|attr| self[attr].to_s.empty?}
    end

    def to_s
      "#<BulkArchivalObjectUpdater::DigitalObjectCandidate #{self.to_h.inspect}>"
    end

    def inspect
      to_s
    end
  end

  AccessionCandidate = Struct.new(:id_0, :id_1, :id_2, :id_3) do
    def empty?
      id_0.nil? && id_1.nil? && id_2.nil? && id_3.nil?
    end

    def to_json
      ASUtils.to_json([id_0, id_1, id_2, id_3])
    end

    def to_s
      "#<BulkArchivalObjectUpdater::AccessionCandidate #{self.to_h.inspect}>"
    end

    def inspect
      to_s
    end
  end

  def create_missing_top_containers(in_sheet)
    (in_sheet.keys - @top_containers_in_resource.keys).each do |candidate_to_create|
      tc_json = JSONModel::JSONModel(:top_container).new
      tc_json.indicator = candidate_to_create.top_container_indicator
      tc_json.type = candidate_to_create.top_container_type
      tc_json.barcode = candidate_to_create.top_container_barcode

      info_messages.push("Creating top container for type: #{candidate_to_create.top_container_type} indicator: #{candidate_to_create.top_container_indicator}")

      tc = TopContainer.create_from_json(tc_json)

      @top_containers_in_resource[candidate_to_create] = tc.uri
    end
  end

  def apply_digital_objects_changes(in_sheet, db)
    identifiers_by_digital_object_id = {}

    # NOTE: digital_object_id is unique within the repository!
    #
    # Check if any of the digital objects referenced in the spreadsheet
    # already exist.
    candidate_ids = in_sheet.keys.map {|candidate| candidate.digital_object_id}.uniq.compact
    db[:digital_object]
    .filter(:digital_object_id => candidate_ids)
    .select(:id, :repo_id, :digital_object_id)
    .each do |row|
      identifiers_by_digital_object_id[row[:digital_object_id]] = {
        uri: JSONModel::JSONModel(:digital_object).uri_for(row[:id], :repo_id => row[:repo_id]),
        id: row[:id]
      }
    end

    candidates_for_update = {}

    in_sheet.keys.each do |digital_object_candidate|
      # no values! move on...
      next if digital_object_candidate.empty?

      digital_object_exists = identifiers_by_digital_object_id.include?(digital_object_candidate.digital_object_id)

      # allow linking to a digital object with its ID alone i.e. no updates!
      next if digital_object_candidate.link_only? && digital_object_exists

      if digital_object_exists
        # Digital object exists for this digital_object_id! So stash it and we'll
        # check it for changes in a moment...
        candidates_for_update[identifiers_by_digital_object_id.fetch(digital_object_candidate.digital_object_id).fetch(:id)] = digital_object_candidate
      else
        # No digital object exists with this digital_object_id,
        # so we better create a new one.
        do_json = JSONModel::JSONModel(:digital_object).new #._always_valid!
        do_json.digital_object_id = digital_object_candidate.digital_object_id
        do_json.title = digital_object_candidate.digital_object_title
        do_json.publish = digital_object_candidate.digital_object_publish
        unless [digital_object_candidate.file_version_file_uri, digital_object_candidate.file_version_caption].all? {|v| v.to_s.empty?}
          do_json.file_versions = [{
                                     'jsonmodel_type' => 'file_version',
                                     'file_uri' => digital_object_candidate.file_version_file_uri,
                                     'caption' => digital_object_candidate.file_version_caption,
                                     'publish' => digital_object_candidate.file_version_publish,
                                   }]
        end

        obj = DigitalObject.create_from_json(do_json)

        info_messages.push("Created digital object #{do_json.digital_object_id} - #{do_json.title}")

        identifiers_by_digital_object_id[digital_object_candidate.digital_object_id] = {
          uri: obj.uri,
          id: obj.id
        }

        updated_uris << obj.uri
      end
    end

    unless candidates_for_update.empty?
      # Batch update the digital objects
      candidates_for_update.keys.each_slice(BATCH_SIZE) do |batch|
        objs = DigitalObject.filter(:id => batch).all
        jsons = DigitalObject.sequel_to_jsonmodel(objs)

        objs.zip(jsons).each do |obj, json|
          candidate = candidates_for_update.fetch(obj.id)

          # We only want to update the digital object if we're sure the
          # spreadsheet contains changes. So double check the record's
          # existing values before firing an update.
          changed = false

          if json.title != candidate.digital_object_title
            json.title = candidate.digital_object_title
            changed = true
          end

          if json.publish != !!candidate.digital_object_publish
            json.publish = !!candidate.digital_object_publish
            changed = true
          end

          has_file_version_values = ![candidate.file_version_file_uri, candidate.file_version_caption].all? {|v| v.to_s.empty?}
          if (file_version = json.file_versions.first)
            if has_file_version_values
              # update the file version
              if file_version['file_uri'] != candidate.file_version_file_uri
                file_version['file_uri'] = candidate.file_version_file_uri
                changed = true
              end

              if file_version['caption'] != candidate.file_version_caption
                file_version['caption'] = candidate.file_version_caption
                changed = true
              end

              if file_version['publish'] != !!candidate.file_version_publish
                file_version['publish'] = candidate.file_version_publish
                changed = true
              end
            else
              # delete the file version!
              json.file_versions.delete_at(0)
              changed = true
            end
          elsif has_file_version_values
            json.file_versions << {
              'jsonmodel_type' => 'file_version',
              'file_uri' => candidate.file_version_file_uri,
              'caption' => candidate.file_version_caption,
            }
            changed = true
          end

          if changed
            obj.update_from_json(json)

            info_messages.push("Updated digital object #{json.digital_object_id} - #{json.title}")

            updated_uris << obj.uri
          end
        end
      end
    end

    identifiers_by_digital_object_id
  end

  def find_subrecord_columns(column_by_path)
    out = {}

    column_by_path.each do |path, column|
      if [:top_container_type, :top_container_indicator, :top_container_barcode].include?(column.name)
        out[:top_container] ||= {}
        out[:top_container][path] = column
      end

      out[column.jsonmodel] ||= {}
      out[column.jsonmodel][path] = column
    end

    out
  end

  def extract_top_containers_from_sheet(filename, top_container_columns)
    top_containers = {}

    each_row(filename) do |row|
      by_index = {}
      top_container_columns.each do |path, column|
        by_index[column.index] ||= TopContainerCandidate.new
        by_index[column.index][column.name] = column.sanitise_incoming_value(row.fetch(path))
      end

      by_index.values.reject(&:empty?).each do |top_container|
        top_containers[top_container] = nil
      end
    end

    top_containers
  end

  def extract_digital_objects_from_sheet(filename, digital_object_columns)
    digital_objects = {}

    each_row(filename) do |row|
      by_index = {}
      digital_object_columns.each do |path, column|
        by_index[column.index] ||= DigitalObjectCandidate.new
        by_index[column.index][column.name] = column.sanitise_incoming_value(row.fetch(path))
      end

      by_index.values.reject(&:empty?).each do |digital_object|
        digital_objects[digital_object] = nil
      end
    end

    digital_objects
  end

  def extract_accessions_from_sheet(db, filename, related_accession_columns)
    accessions = {}

    each_row(filename) do |row|
      by_index = {}
      related_accession_columns.each do |path, column|
        by_index[column.index] ||= AccessionCandidate.new
        by_index[column.index][column.name] = column.sanitise_incoming_value(row.fetch(path))
      end

      by_index.values.reject(&:empty?).each do |candidate|
        accessions[candidate] = nil
      end
    end

    # lookup URIs for candidates
    db[:accession]
      .filter(:identifier => accessions.keys.map {|candidate| candidate.to_json})
      .select(:id, :repo_id, :identifier)
      .each do |row|
      bits = Identifiers.parse(row[:identifier])
      candidate = AccessionCandidate.new(bits[0], bits[1].to_s, bits[2], bits[3])
      accessions[candidate] = JSONModel::JSONModel(:accession).uri_for(row[:id], :repo_id => row[:repo_id])
    end

    accessions
  end

  def extract_top_containers_for_resource(db, resource_id)
    result = {}

    db[:instance]
      .join(:sub_container, Sequel.qualify(:sub_container, :instance_id) => Sequel.qualify(:instance, :id))
      .join(:top_container_link_rlshp, Sequel.qualify(:top_container_link_rlshp, :sub_container_id) => Sequel.qualify(:sub_container, :id))
      .join(:top_container, Sequel.qualify(:top_container, :id) => Sequel.qualify(:top_container_link_rlshp, :top_container_id))
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:instance, :archival_object_id))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
      .select(Sequel.as(Sequel.qualify(:top_container, :id), :top_container_id),
              Sequel.as(Sequel.qualify(:top_container, :repo_id), :repo_id),
              Sequel.as(Sequel.qualify(:top_container, :type_id), :top_container_type_id),
              Sequel.as(Sequel.qualify(:top_container, :indicator), :top_container_indicator),
              Sequel.as(Sequel.qualify(:top_container, :barcode), :top_container_barcode))
      .each do |row|
      tc = TopContainerCandidate.new
      tc.top_container_type = BackendEnumSource.value_for_id('container_type', row[:top_container_type_id])
      tc.top_container_indicator = row[:top_container_indicator]
      tc.top_container_barcode = row[:top_container_barcode]

      result[tc] = JSONModel::JSONModel(:top_container).uri_for(row[:top_container_id], :repo_id => row[:repo_id])
    end

    result
  end

  def resource_ids_in_play(filename)
    ao_ids = extract_ao_ids(filename)

    ArchivalObject
      .filter(:id => ao_ids)
      .select(:root_record_id)
      .distinct(:root_record_id)
      .map {|row| row[:root_record_id]}
  end

  def check_sheet(filename)
    errors = []

    # Check AOs exist
    ao_ids = extract_ao_ids(filename)
    existing_ao_ids = ArchivalObject
                        .filter(:id => ao_ids)
                        .select(:id)
                        .map {|row| row[:id]}

    (ao_ids - existing_ao_ids).each do |missing_id|
      errors << {
        sheet: SpreadsheetBuilder::SHEET_NAME,
        row: 'N/A',
        column: 'id',
        errors: ["Archival Object not found for id: #{missing_id}"]
      }
    end

    # Check AOs all from same resource
    resource_ids = resource_ids_in_play(filename)

    if resource_ids.length > 1
      errors << {
        sheet: SpreadsheetBuilder::SHEET_NAME,
        row: 'N/A',
        column: 'id',
        errors: ["Archival Objects must all belong to the same resource."]
      }
    end

    if errors.length > 0
      raise BulkUpdateFailed.new(errors)
    end
  end

  def batch_rows(filename)
    to_enum(:each_row, filename).each_slice(BATCH_SIZE) do |batch|
      yield batch
    end
  end

  def each_row(filename)
    headers = nil

    XLSXStreamingReader.new(filename).each(SpreadsheetBuilder::SHEET_NAME).each_with_index do |row, idx|
      if idx == 0
        # header label row is ignored
        next
      elsif idx == 1
        headers = row_values(row)
      else
        values = row_values(row)

        next if values.all? {|v| v.nil?}

        yield Row.new(headers.zip(values).to_h, idx + 1)
      end
    end
  end

  class BulkUpdateFailed < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def to_json
      @errors
    end
  end

  Row = Struct.new(:values, :row_number) do
    def fetch(*args)
      self.values.fetch(*args)
    end

    def empty?
      values.all? {|_, v| v.to_s.strip.empty?}
    end
  end

  def row_values(row)
    row.map {|value|
      if value.nil?
        value
      elsif value.is_a?(String)
        result = value.strip
        result.empty? ? nil : result
      else
        # retain type int, date, time, etc
        value
      end
    }
  end

  def missing_top_container_error_message(container, available_top_containers)
    message = ""

    message += "Top container not found attached within resource: #{container.inspect}\n"
    message += "Set 'create_missing_top_containers' to true inside AppConfig, to create Top Containers that do not exist.\n"
    message += "The following top containers are attached within this resource:\n"
    message += available_top_containers.map do |tc|
      "#{ tc.inspect }\n"
    end.join("")

    message
  end
end
