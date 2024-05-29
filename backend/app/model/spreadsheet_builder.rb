class SpreadsheetBuilder

  ALWAYS_FIELDS = ['id', 'lock_version', 'title']

  def initialize(resource_uri, ao_uris, min_subrecords, extra_subrecords, min_notes, selected_columns)
    @resource_uri = resource_uri
    @resource_id = JSONModel.parse_reference(@resource_uri).fetch(:id)
    @ao_uris = []
    @ao_ids = []

    ao_uris.each do |uri|
      parsed = JSONModel.parse_reference(uri)
      if parsed[:type] == 'archival_object'
        @ao_uris << uri
        @ao_ids << parsed.fetch(:id)
      end
    end

    @subrecord_counts = calculate_subrecord_counts(min_subrecords, extra_subrecords, min_notes)
    @selected_columns = selected_columns + ALWAYS_FIELDS
  end

  BATCH_SIZE = 200
  SHEET_NAME = 'Updates'

  class StringColumn
    attr_accessor :name, :column, :index, :jsonmodel, :width, :locked, :property_name

    def initialize(jsonmodel, name, opts = {})
      @jsonmodel = jsonmodel
      @name = name
      @header_label = opts.fetch(:header_label, nil)
      @column = opts.fetch(:column, name).intern
      @width = opts.fetch(:width, nil)
      @locked = opts.fetch(:locked, false)
      @property_name = opts.fetch(:property_name, jsonmodel).to_s
      @i18n = opts.fetch(:i18n, I18n.t("#{@jsonmodel}.#{@name}", :default => @name))
      @i18n_proc = opts.fetch(:i18n_proc, nil)
      @path_proc = opts.fetch(:path_proc, nil)
    end

    def value_for(column_value)
      column_value
    end

    def header_label
      if @header_label.nil?
        if @i18n_proc
          @index = 0 if @index.nil?
          @header_label = @i18n_proc.call(self)
        else
          if @index.nil?
            @header_label = @i18n
          else
            @header_label = "#{I18n.t("#{jsonmodel}._singular")} #{index + 1} - #{@i18n}"
          end
        end
      end
      @header_label
    end

    def path
      if @path_proc
        return @path_proc.call(self)
      end

      if jsonmodel == :archival_object
        name.to_s
      else
        [@property_name, index, name].join('/')
      end
    end

    def sanitise_incoming_value(value)
      return nil if value.nil?

      value.to_s.strip
    end
  end

  class DateStringColumn < StringColumn
    def initialize(jsonmodel, name, opts = {})
      super(jsonmodel, name, opts)
    end

    def sanitise_incoming_value(value)
      return nil if value.nil?

      if value.is_a?(Date)
        value.iso8601
      elsif value.is_a?(Time)
        value.to_date.iso8601
      else
        value.to_s.strip
      end
    end
  end

  class NoteContentColumn < StringColumn
    attr_accessor :note_jsonmodel

    def initialize(jsonmodel, name, note_jsonmodel = 'note_multipart', opts = {})
      super(jsonmodel, name, opts)
      @note_jsonmodel = note_jsonmodel
    end

    def header_label
      "#{I18n.t('note._singular')} #{I18n.t("enumerations.#{@note_jsonmodel}_type.#{@name}")} - #{index + 1} - Content"
    end

    def path
      [@jsonmodel.to_s, @name.to_s, @index.to_s, 'content'].join('/')
    end

    def multipart?
      @note_jsonmodel == 'note_multipart'
    end
  end

  class EnumColumn < StringColumn
    attr_accessor :enum_name, :skip_values

    def initialize(jsonmodel, name, enum_name, opts = {})
      super(jsonmodel, name, {:column => "#{name}_id"}.merge(opts))
      @enum_name = enum_name
      @skip_values = opts.fetch(:skip_enum_values, [])
    end

    def value_for(enum_id)
      EnumMapper.enum_id_to_spreadsheet_value(enum_id, @enum_name)
    end

    def sanitise_incoming_value(value)
      EnumMapper.spreadsheet_value_to_enum(value)
    end
  end

  class BooleanColumn < StringColumn
    def value_for(column_value)
      (column_value == 1).to_s
    end

    def sanitise_incoming_value(value)
      return nil if value.to_s.empty?

      value == 'true'
    end
  end

  class AccessionLookupColumn < StringColumn
  end

  SUBRECORDS_OF_INTEREST = [:date, :extent]
  FIELDS_OF_INTEREST = {
    :archival_object => [
      StringColumn.new(:archival_object, :id, :header_label => "Id", :locked => true),
      StringColumn.new(:archival_object, :lock_version, :header_label => "Version", :locked => true),
      StringColumn.new(:archival_object, :title, :width => 30),
      EnumColumn.new(:archival_object, :level, 'archival_record_level', :width => 15),
      StringColumn.new(:archival_object, :ref_id, :width => 15, :locked => true),
      StringColumn.new(:archival_object, :component_id, :width => 15),
      StringColumn.new(:archival_object, :repository_processing_note, :width => 30),
      BooleanColumn.new(:archival_object, :publish),
    ],
    :date => [
      EnumColumn.new(:date, :label, 'date_label', :property_name => :dates),
      StringColumn.new(:date, :expression, :width => 15, :property_name => :dates),
      DateStringColumn.new(:date, :begin, :width => 10, :property_name => :dates),
      DateStringColumn.new(:date, :end, :width => 10, :property_name => :dates),
      EnumColumn.new(:date, :certainty, 'date_certainty', :property_name => :dates),
    ],
    :extent => [
      EnumColumn.new(:extent, :portion, 'extent_portion', :width => 15, :property_name => :extents),
      StringColumn.new(:extent, :number, :width => 15, :property_name => :extents),
      EnumColumn.new(:extent, :extent_type, 'extent_extent_type', :width => 15, :property_name => :extents),
      StringColumn.new(:extent, :container_summary, :width => 20, :property_name => :extents),
      StringColumn.new(:extent, :physical_details, :width => 20, :property_name => :extents),
      StringColumn.new(:extent, :dimensions, :width => 15, :property_name => :extents),
    ],
    :instance => [
      EnumColumn.new(:instance, :instance_type, 'instance_instance_type', :property_name => :instances, :skip_enum_values => ['digital_object']),
      EnumColumn.new(:instance, :top_container_type, 'container_type', :property_name => :instances, :i18n => "Top Container Type"),    # Sorry, these are hardcoded as
      StringColumn.new(:instance, :top_container_indicator, :property_name => :instances, :i18n => "Top Container Indicator"),          # all top and sub container I18n
      StringColumn.new(:instance, :top_container_barcode, :property_name => :instances, :i18n => "Top Container Barcode"),              # are available only in the
      EnumColumn.new(:instance, :sub_container_type_2, 'container_type', :property_name => :instances, :i18n => "Child Type"),          # frontend... WHY?!
      StringColumn.new(:instance, :sub_container_indicator_2, :property_name => :instances, :i18n => "Child Indicator"),                #
      StringColumn.new(:instance, :sub_container_barcode_2, :property_name => :instances, :i18n => "Child Container Barcode"),          #
      EnumColumn.new(:instance, :sub_container_type_3, 'container_type', :property_name => :instances, :i18n => "Grandchild Type"),     # Boo.
      StringColumn.new(:instance, :sub_container_indicator_3, :property_name => :instances, :i18n => "Grandchild Indicator"),           #
    ],
    :digital_object => [
      StringColumn.new(:digital_object, :digital_object_id, :i18n => "Identifier"),
      StringColumn.new(:digital_object, :digital_object_title, :i18n => "Title"),
      BooleanColumn.new(:digital_object, :digital_object_publish, :i18n => "Publish?"),
      StringColumn.new(:digital_object, :file_version_file_uri, :i18n => "File URI"),
      StringColumn.new(:digital_object, :file_version_caption, :i18n => "File Caption"),
      BooleanColumn.new(:digital_object, :file_version_publish, :i18n => "File Publish?"),
    ],
    :related_accession => [
      StringColumn.new(:related_accession, :id_0, :property_name => :related_accessions, :i18n => 'ID Part 1'),
      StringColumn.new(:related_accession, :id_1, :property_name => :related_accessions, :i18n => 'ID Part 2'),
      StringColumn.new(:related_accession, :id_2, :property_name => :related_accessions, :i18n => 'ID Part 3'),
      StringColumn.new(:related_accession, :id_3, :property_name => :related_accessions, :i18n => 'ID Part 4'),
    ],
    :language_and_script => [
      EnumColumn.new(:language_and_script, :language, 'language_iso639_2', :i18n => 'Language'),
      EnumColumn.new(:language_and_script, :script, 'script_iso15924', :i18n => 'Script')
    ],
    :note_langmaterial => [
      StringColumn.new(:note_langmaterial, :content, :width => 30, :i18n_proc => proc {|col| "Language Note - #{col.index + 1} - Content"})
    ],
  }

  MULTIPART_NOTES_OF_INTEREST = [
    :accessrestrict,
    :scopecontent,
    :bioghist,
    :accruals,
    :dimensions,
    :altformavail,
    :odd,
    :phystech,
    :processinfo,
    :relatedmaterial,
    :separatedmaterial,
  ]

  SINGLEPART_NOTES_OF_INTEREST = [
    :abstract,
    :physdesc,
  ]

  EXTRA_NOTE_FIELDS = {
    :_all_ => [
      StringColumn.new(:note, :label,
                       :i18n_proc => proc {|col|
                         "#{I18n.t('note._singular')} #{I18n.t("enumerations.note_multipart_type.#{col.jsonmodel}", :default => I18n.t("enumerations.note_singlepart_type.#{col.jsonmodel}"))} - #{col.index + 1} - Label"
                       },
                       :path_proc => proc {|col|
                         ['note', col.jsonmodel.to_s, col.index.to_s, col.name.to_s].join('/')
                       }),
    ],
    :accessrestrict => [
      DateStringColumn.new(:accessrestrict, :begin, :width => 10,
                           :property_name => :rights_restriction,
                           :i18n_proc => proc {|col|
                             "#{I18n.t('note._singular')} #{I18n.t("enumerations.note_multipart_type.accessrestrict")} - #{col.index + 1} - Begin"
                           },
                           :path_proc => proc {|col|
                             ['note', col.jsonmodel.to_s, col.index.to_s, col.name.to_s].join('/')
                           }),
      DateStringColumn.new(:accessrestrict, :end, :width => 10,
                           :property_name => :rights_restriction,
                           :i18n_proc => proc {|col|
                             "#{I18n.t('note._singular')} #{I18n.t("enumerations.note_multipart_type.accessrestrict")} - #{col.index + 1} - End"
                           },
                           :path_proc => proc {|col|
                             ['note', col.jsonmodel.to_s, col.index.to_s, col.name.to_s].join('/')
                           }),
      EnumColumn.new(:accessrestrict, :local_access_restriction_type, 'restriction_type',
                     :width => 15,
                     :property_name => :rights_restriction,
                     :i18n_proc => proc {|col|
                       "#{I18n.t('note._singular')} #{I18n.t("enumerations.note_multipart_type.accessrestrict")} - #{col.index + 1} - Type"
                     },
                     :path_proc => proc {|col|
                       ['note', col.jsonmodel.to_s, col.index.to_s, col.name.to_s].join('/')
                     }),
    ]
  }

  def calculate_subrecord_counts(min_subrecords, extra_subrecords, min_notes)
    results = {}

    DB.open do |db|
      SUBRECORDS_OF_INTEREST.each do |subrecord|
        max = db[subrecord]
                .filter(:archival_object_id => @ao_ids)
                .group_and_count(:archival_object_id)
                .max(:count) || 0

        # Dates, extents: At least min_subrecords or extra_subrecords more than the max
        results[subrecord] = [min_subrecords, max + extra_subrecords].max
      end

      # Instances are special
      instances_max = db[:instance]
        .filter(:archival_object_id => @ao_ids)
        .filter(Sequel.~(:instance_type_id => BackendEnumSource.id_for_value('instance_instance_type', 'digital_object')))
        .group_and_count(:archival_object_id)
        .max(:count) || 0

      results[:instance] = [min_subrecords, instances_max + extra_subrecords].max

      # Digital Object Instances are special too
      digital_objects_max = db[:instance]
                                      .filter(:archival_object_id => @ao_ids)
                                      .filter(:instance_type_id => BackendEnumSource.id_for_value('instance_instance_type', 'digital_object'))
                                      .group_and_count(:archival_object_id)
                                      .max(:count) || 0

      results[:digital_object] = [min_subrecords, digital_objects_max + extra_subrecords].max

      # Related Accessions are special and only available if the as_accession_links plugin is enabled
      if SpreadsheetBuilder.related_accessions_enabled?
        related_accession_max = db[:accession_component_links_rlshp]
                                  .filter(:archival_object_id => @ao_ids)
                                  .group_and_count(:archival_object_id)
                                  .max(:count) || 0

        results[:related_accession] = [related_accession_max, 1].max
      end

      # Ok... lang_material are their own kind of special too:
      #
      # they have a one-to-many language_and_script
      language_and_script_max = db[:lang_material]
                                  .join(:language_and_script, Sequel.qualify(:language_and_script, :lang_material_id) => Sequel.qualify(:lang_material, :id))
                                  .filter(Sequel.qualify(:lang_material, :archival_object_id) => @ao_ids)
                                  .group_and_count(Sequel.qualify(:lang_material, :archival_object_id))
                                  .max(:count) || 0
      results[:language_and_script] = [language_and_script_max, 1].max

      # and one-to-many note_langmaterial too
      note_langmaterial_max = db[:lang_material]
                                .join(:note, Sequel.qualify(:note, :lang_material_id) => Sequel.qualify(:lang_material, :id))
                                .filter(Sequel.qualify(:lang_material, :archival_object_id) => @ao_ids)
                                .group_and_count(Sequel.qualify(:lang_material, :archival_object_id))
                                .max(:count) || 0
      results[:note_langmaterial] = [note_langmaterial_max, 1].max

      # Notes!
      notes_max_counts = {}

      db[:note]
        .filter(:archival_object_id => @ao_ids)
        .select(:archival_object_id, :notes)
        .each do |row|
        note_json = JSON.parse(row[:notes])
        note_type = note_json.fetch('type', 'NOT_SUPPORTED')

        notes_max_counts[note_type] ||= 0
        notes_max_counts[note_type] += 1
      end

      (MULTIPART_NOTES_OF_INTEREST + SINGLEPART_NOTES_OF_INTEREST).each do |note_type|
        # Notes: At least min_notes of each type
        results[note_type] = [min_notes, notes_max_counts.fetch(note_type, 0)].max
      end
    end

    results
  end

  def build_filename
    "bulk_update.resource_#{@resource_id}.#{Date.today.iso8601}.xlsx"
  end

  def subrecords_iterator
    SUBRECORDS_OF_INTEREST
      .map do |subrecord|
      @subrecord_counts.fetch(subrecord).times do |i|
        yield(subrecord, i)
      end
    end
  end

  def instances_iterator
    @subrecord_counts.fetch(:instance).times do |i|
      yield(:instance, i)
    end
  end

  def digital_objects_iterator
    @subrecord_counts.fetch(:digital_object).times do |i|
      yield(:digital_object, i)
    end
  end

  def related_accessions_iterator
    @subrecord_counts.fetch(:related_accession, 0).times do |i|
      yield(:related_accession, i)
    end
  end

  def notes_iterator
    MULTIPART_NOTES_OF_INTEREST
      .map do |note_type|
      @subrecord_counts.fetch(note_type).times do |i|
        yield('note_multipart', note_type, i)
      end
    end

    SINGLEPART_NOTES_OF_INTEREST
      .map do |note_type|
      @subrecord_counts.fetch(note_type).times do |i|
        yield('note_singlepart', note_type, i)
      end
    end
  end

  def language_and_script_iterator
    @subrecord_counts.fetch(:language_and_script, 0).times do |i|
      yield(:language_and_script, i)
    end
  end

  def note_langmaterial_iterator
    @subrecord_counts.fetch(:note_langmaterial, 0).times do |i|
      yield(:note_langmaterial, i)
    end
  end

  def human_readable_headers
    all_columns.map {|col| col.header_label}
  end

  def machine_readable_headers
    all_columns.map {|col| col.path}
  end

  def selected?(column_group)
    @selected_columns.include?(column_group.to_s)
  end

  def all_columns
    return @columns if @columns

    result = []

    FIELDS_OF_INTEREST.fetch(:archival_object).each do |column|
      result << column if selected?(column.name.to_s)
    end

    if selected?('langmaterial')
      language_and_script_iterator do |_, index|
        FIELDS_OF_INTEREST.fetch(:language_and_script).each do |column|
          column = column.clone
          column.index = index
          result << column
        end
      end

      note_langmaterial_iterator do |_, index|
        FIELDS_OF_INTEREST.fetch(:note_langmaterial).each do |column|
          column = column.clone
          column.index = index
          result << column
        end
      end
    end

    subrecords_iterator do |subrecord, index|
      unless selected?(subrecord.to_s)
        next
      end

      FIELDS_OF_INTEREST.fetch(subrecord).each do |column|
        column = column.clone
        column.index = index
        result << column
      end
    end

    if selected?('instance')
      instances_iterator do |_, index|
        FIELDS_OF_INTEREST.fetch(:instance).each do |column|
          column = column.clone
          column.index = index
          result << column
        end
      end
    end

    if selected?('digital_object')
      digital_objects_iterator do |_, index|
        FIELDS_OF_INTEREST.fetch(:digital_object).each do |column|
          column = column.clone
          column.index = index
          result << column
        end
      end
    end

    if selected?('related_accession')
      related_accessions_iterator do |_, index|
        FIELDS_OF_INTEREST.fetch(:related_accession).each do |column|
          column = column.clone
          column.index = index
          result << column
        end
      end
    end

    notes_iterator do |jsonmodel_type, note_type, index|
      unless selected?("note_#{note_type}")
        next
      end

      column = NoteContentColumn.new(:note, note_type, jsonmodel_type, :width => 30)
      column.index = index
      result << column

      self.class.extra_note_fields_for_type(note_type).each do |extra_column|
        column = extra_column.clone
        column.index = index

        result << column
      end
    end

    @columns = result
  end

  def self.extra_note_fields_for_type(note_type)
    (EXTRA_NOTE_FIELDS.fetch(:_all_) + EXTRA_NOTE_FIELDS.fetch(note_type, [])).map do |column|
      col = column.clone
      col.jsonmodel = note_type
      col
    end
  end

  def dataset_iterator(&block)
    DB.open do |db|
      @ao_ids.each_slice(BATCH_SIZE) do |batch|
        base_fields = [:id, :lock_version] + FIELDS_OF_INTEREST.fetch(:archival_object).map {|field| field.column}
        base = ArchivalObject
                .filter(:id => batch)
                .order(Sequel.lit("FIELD(id, #{batch.join(',')})"))
                .select(*base_fields)

        subrecord_datasets = {}
        SUBRECORDS_OF_INTEREST.each do |subrecord|
          next unless selected?(subrecord.to_s)

          subrecord_fields = [:archival_object_id] + FIELDS_OF_INTEREST.fetch(subrecord).map {|field| field.column}

          subrecord_datasets[subrecord] = {}

          db[subrecord]
            .filter(:archival_object_id => batch)
            .select(*subrecord_fields)
            .each do |row|
            subrecord_datasets[subrecord][row[:archival_object_id]] ||= []
            subrecord_datasets[subrecord][row[:archival_object_id]] << FIELDS_OF_INTEREST.fetch(subrecord).map {|field| [field.name, field.value_for(row[field.column])]}.to_h
          end
        end

        if selected?('instance')
          # Instances are special
          db[:instance]
            .join(:sub_container, Sequel.qualify(:sub_container, :instance_id) => Sequel.qualify(:instance, :id))
            .join(:top_container_link_rlshp, Sequel.qualify(:top_container_link_rlshp, :sub_container_id) => Sequel.qualify(:sub_container, :id))
            .join(:top_container, Sequel.qualify(:top_container, :id) => Sequel.qualify(:top_container_link_rlshp, :top_container_id))
            .filter(Sequel.qualify(:instance, :archival_object_id) => batch)
            .filter(Sequel.~(Sequel.qualify(:instance, :instance_type_id) => BackendEnumSource.id_for_value('instance_instance_type', 'digital_object')))
            .select(
              Sequel.as(Sequel.qualify(:instance, :archival_object_id), :archival_object_id),
              Sequel.as(Sequel.qualify(:instance, :instance_type_id), :instance_type_id),
              Sequel.as(Sequel.qualify(:top_container, :type_id), :top_container_type_id),
              Sequel.as(Sequel.qualify(:top_container, :indicator), :top_container_indicator),
              Sequel.as(Sequel.qualify(:top_container, :barcode), :top_container_barcode),
              Sequel.as(Sequel.qualify(:sub_container, :type_2_id), :sub_container_type_2_id),
              Sequel.as(Sequel.qualify(:sub_container, :indicator_2), :sub_container_indicator_2),
              Sequel.as(Sequel.qualify(:sub_container, :barcode_2), :sub_container_barcode_2),
              Sequel.as(Sequel.qualify(:sub_container, :type_3_id), :sub_container_type_3_id),
              Sequel.as(Sequel.qualify(:sub_container, :indicator_3), :sub_container_indicator_3),
            ).each do |row|
            subrecord_datasets[:instance] ||= {}
            subrecord_datasets[:instance][row[:archival_object_id]] ||= []
            subrecord_datasets[:instance][row[:archival_object_id]] << {
              :instance_type => EnumMapper.enum_id_to_spreadsheet_value(row[:instance_type_id], 'instance_instance_type'),
              :top_container_type => EnumMapper.enum_id_to_spreadsheet_value(row[:top_container_type_id], 'container_type'),
              :top_container_indicator => row[:top_container_indicator],
              :top_container_barcode => row[:top_container_barcode],
              :sub_container_type_2 => EnumMapper.enum_id_to_spreadsheet_value(row[:sub_container_type_2_id], 'container_type'),
              :sub_container_indicator_2 => row[:sub_container_indicator_2],
              :sub_container_barcode_2 => row[:sub_container_barcode_2],
              :sub_container_type_3 => EnumMapper.enum_id_to_spreadsheet_value(row[:sub_container_type_3_id], 'container_type'),
              :sub_container_indicator_3 => row[:sub_container_indicator_3],
            }
          end
        end

        if selected?('digital_object')
          # Digital Object Instances
          #
          # - only support editing one file version per digital object
          #   (or one row per digital object instance)
          seen_file_versions = {}
          db[:instance]
            .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
            .join(:digital_object, Sequel.qualify(:digital_object, :id) => Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
            .left_join(:file_version, Sequel.qualify(:file_version, :digital_object_id) => Sequel.qualify(:digital_object, :id))
            .filter(Sequel.qualify(:instance, :archival_object_id) => batch)
            .filter(Sequel.qualify(:instance, :instance_type_id) => BackendEnumSource.id_for_value('instance_instance_type', 'digital_object'))
            .select(
              Sequel.as(Sequel.qualify(:instance, :archival_object_id), :archival_object_id),
              Sequel.as(Sequel.qualify(:instance_do_link_rlshp, :id), :rlshp_id),
              Sequel.as(Sequel.qualify(:digital_object, :digital_object_id), :digital_object_id),
              Sequel.as(Sequel.qualify(:digital_object, :title), :digital_object_title),
              Sequel.as(Sequel.qualify(:digital_object, :publish), :digital_object_publish),
              Sequel.as(Sequel.qualify(:file_version, :id), :file_version_id),
              Sequel.as(Sequel.qualify(:file_version, :file_uri), :file_version_file_uri),
              Sequel.as(Sequel.qualify(:file_version, :caption), :file_version_caption),
              Sequel.as(Sequel.qualify(:file_version, :publish), :file_version_publish),
              ).each do |row|
            next if seen_file_versions.fetch(row[:rlshp_id], false)

            seen_file_versions[row[:rlshp_id]] = true

            subrecord_datasets[:digital_object] ||= {}
            subrecord_datasets[:digital_object][row[:archival_object_id]] ||= []
            subrecord_datasets[:digital_object][row[:archival_object_id]] << {
              :digital_object_id => row[:digital_object_id],
              :digital_object_title => row[:digital_object_title],
              :digital_object_publish => (row[:digital_object_publish] == 1).to_s,
              :file_version_file_uri => row[:file_version_file_uri],
              :file_version_caption => row[:file_version_caption],
              :file_version_publish => (row[:file_version_publish] == 1).to_s,
            }
          end
        end

        # Related Accessions are special
        if SpreadsheetBuilder.related_accessions_enabled? && selected?('related_accession')
          db[:accession_component_links_rlshp]
            .join(:accession, Sequel.qualify(:accession, :id) => Sequel.qualify(:accession_component_links_rlshp, :accession_id))
            .filter(Sequel.qualify(:accession_component_links_rlshp, :archival_object_id) => batch)
            .select(
              Sequel.qualify(:accession_component_links_rlshp, :archival_object_id),
              Sequel.qualify(:accession, :identifier),
            ).each do |row|
            subrecord_datasets[:related_accession] ||= {}
            subrecord_datasets[:related_accession][row[:archival_object_id]] ||= []

            accession_data = {}
            bits = Identifiers.parse(row[:identifier])
            4.times do |index|
              accession_data[:"id_#{index}"] = bits[index] || ''
            end

            subrecord_datasets[:related_accession][row[:archival_object_id]] << accession_data
          end
        end

        if selected?('langmaterial')
          # lang_material specialness
          db[:lang_material]
            .join(:language_and_script, Sequel.qualify(:language_and_script, :lang_material_id) => Sequel.qualify(:lang_material, :id))
            .filter(Sequel.qualify(:lang_material, :archival_object_id) => batch)
            .select(Sequel.qualify(:lang_material, :archival_object_id),
                    Sequel.qualify(:language_and_script, :language_id),
                    Sequel.qualify(:language_and_script, :script_id))
            .each do |row|
            subrecord_datasets[:language_and_script] ||= {}
            subrecord_datasets[:language_and_script][row[:archival_object_id]] ||= []
            subrecord_datasets[:language_and_script][row[:archival_object_id]] << {
              :language => row[:language_id] ? EnumMapper.enum_id_to_spreadsheet_value(row[:language_id], 'language_iso639_2') : nil,
              :script => row[:script_id] ? EnumMapper.enum_id_to_spreadsheet_value(row[:script_id], 'script_iso15924') : nil,
            }
          end

          db[:lang_material]
            .join(:note, Sequel.qualify(:note, :lang_material_id) => Sequel.qualify(:lang_material, :id))
            .filter(Sequel.qualify(:lang_material, :archival_object_id) => batch)
            .select(Sequel.qualify(:lang_material, :archival_object_id),
                    Sequel.qualify(:note, :notes))
            .each do |row|
            note_json = ASUtils.json_parse(row[:notes])

            subrecord_datasets[:note_langmaterial] ||= {}
            subrecord_datasets[:note_langmaterial][row[:archival_object_id]] ||= []
            subrecord_datasets[:note_langmaterial][row[:archival_object_id]] << {
              :content => Array(note_json['content']).first,
            }
          end
        end

        # Notes
        db[:note]
          .filter(:archival_object_id => batch)
          .select(:archival_object_id, :notes)
          .order(:archival_object_id, :id)
          .each do |row|
          note_json = ASUtils.json_parse(row[:notes])

          note_type = note_json.fetch('type', 'NOT_SUPPORTED').intern

          next unless (MULTIPART_NOTES_OF_INTEREST + SINGLEPART_NOTES_OF_INTEREST).include?(note_type)
          next unless selected?("note_#{note_type}")

          subrecord_datasets[note_type] ||= {}
          subrecord_datasets[note_type][row[:archival_object_id]] ||= []

          note_data = {}

          if MULTIPART_NOTES_OF_INTEREST.include?(note_type)
            text_subnote = Array(note_json['subnotes']).detect {|subnote| subnote['jsonmodel_type'] == 'note_text'}

            note_data[:content] = text_subnote ? text_subnote['content'] : nil
          elsif SINGLEPART_NOTES_OF_INTEREST.include?(note_type)
            note_data[:content] = Array(note_json['content']).first
          end

          self.class.extra_note_fields_for_type(note_type).each do |extra_column|
            target_record = extra_column.property_name.to_s == 'note' ? note_json : note_json.fetch(extra_column.property_name.to_s, {})
            value = Array(target_record.fetch(extra_column.name.to_s, nil)).first

            if extra_column.is_a?(EnumColumn)
              note_data[extra_column.name] = EnumMapper.enum_to_spreadsheet_value(value, extra_column.enum_name)
            else
              note_data[extra_column.name] = extra_column.value_for(value)
            end

          end

          subrecord_datasets[note_type][row[:archival_object_id]] << note_data
        end

        base.each do |row|
          locked_column_indexes = []

          current_row = []

          all_columns.each_with_index do |column, index|
            locked_column_indexes <<  index if column.locked

            if column.jsonmodel == :archival_object
              current_row << ColumnAndValue.new(column.value_for(row[column.column]), column)
            elsif column.is_a?(NoteContentColumn)
              note_content = subrecord_datasets.fetch(column.name, {}).fetch(row[:id], []).fetch(column.index, {}).fetch(:content, nil)
              if note_content
                current_row << ColumnAndValue.new(note_content, column)
              else
                current_row << ColumnAndValue.new(nil, column)
              end
            elsif EXTRA_NOTE_FIELDS.has_key?(column.jsonmodel)
              note_field_value = subrecord_datasets.fetch(column.jsonmodel, {}).fetch(row[:id], []).fetch(column.index, {}).fetch(column.name, nil)
              if note_field_value
                current_row << ColumnAndValue.new(note_field_value, column)
              else
                current_row << ColumnAndValue.new(nil, column)
              end
            else
              subrecord_data = subrecord_datasets.fetch(column.jsonmodel, {}).fetch(row[:id], []).fetch(column.index, nil)
              if subrecord_data
                # FIXME should do this? current_row << ColumnAndValue.new(column.value_for(value), column)
                current_row << ColumnAndValue.new(subrecord_data.fetch(column.name, nil), column)
              else
                current_row << ColumnAndValue.new(nil, column)
              end
            end
          end

          block.call(current_row, locked_column_indexes)
        end
      end
    end
  end

  ColumnAndValue = Struct.new(:value, :column)

  def to_stream
    io = StringIO.new
    wb = WriteXLSX.new(io)

    # give us `locked` and `unlocked` formatters
    locked = wb.add_format
    locked.set_locked(1)
    locked.set_color('gray')
    locked.set_size(8)
    unlocked = wb.add_format
    unlocked.set_locked(0)

    # and a special one for the human headers row
    human_header_format = wb.add_format
    human_header_format.set_locked(1)
    human_header_format.set_bold
    human_header_format.set_size(12)

    sheet = wb.add_worksheet(SHEET_NAME)
    sheet.freeze_panes(1, 3)

    # protect the sheet to ensure `locked` formatting work
    # and allow a few other basic formatting things
    sheet.protect(nil, {
        :format_columns => true,
        :format_rows => true,
        :sort => true,
      }
    )

    sheet.write_row(0, 0, human_readable_headers)
    sheet.write_row(1, 0, machine_readable_headers)
    sheet.set_row(0, nil, human_header_format)
    sheet.set_row(1, nil, locked)

    # format editable rows to not be locked by default and force
    # string-formatting
    row_format = wb.add_format
    row_format.set_num_format(0x31)
    row_format.set_locked(0)

    rowidx = 2
    dataset_iterator do |row_values, locked_column_indexes|
      # Unlock the entire row to speed things up as we no longer have to write
      # to all the empty cells to unlock them.
      sheet.set_row(rowidx, nil, row_format)

      row_values.each_with_index do |columnAndValue, i|
        if columnAndValue.value
          sheet.write_string(rowidx, i, columnAndValue.value, locked_column_indexes.include?(i) ? locked : unlocked)
        elsif locked_column_indexes.include?(i)
          sheet.write(rowidx, i, columnAndValue.value, locked)
        end
      end

      rowidx += 1
    end

    enum_sheet = wb.add_worksheet('Enums')
    enum_sheet.protect
    enum_counts_by_col = {}
    all_columns.each_with_index do |column, col_index|
      if column.is_a?(EnumColumn)
        enum_sheet.write(0, col_index, column.enum_name)
        enum_values = BackendEnumSource.values_for(column.enum_name)
        enum_values.reject! {|value| column.skip_values.include?(value)}
        enum_values
          .map {|value| EnumMapper.enum_to_spreadsheet_value(value, column.enum_name)}
          .sort_by {|value| value.downcase}
          .each_with_index do |enum, enum_index|
          enum_sheet.write_string(enum_index+1, col_index, enum)
        end
        enum_counts_by_col[col_index] = enum_values.length
      elsif column.is_a?(BooleanColumn)
        enum_sheet.write_string(0, col_index, 'boolean')
        enum_sheet.write_string(1, col_index, 'true')
        enum_sheet.write_string(2, col_index, 'false')
        enum_counts_by_col[col_index] = 2
      end
    end

    all_columns.each_with_index do |column, col_idx|
      if column.is_a?(EnumColumn) || column.is_a?(BooleanColumn)
        sheet.data_validation(2, col_idx, 2 + @ao_ids.length, col_idx,
                              {
                                'validate' => 'list',
                                'source' => "=Enums!$#{index_to_col_reference(col_idx)}$2:$#{index_to_col_reference(col_idx)}$#{enum_counts_by_col.fetch(col_idx)+1}"
                              })
      end

      if column.width
        sheet.set_column(col_idx, col_idx, column.width)
      end
    end

    wb.close
    io.string
  end

  LETTERS = ('A'..'Z').to_a

  # Note: zero-bosed index!
  def index_to_col_reference(n)
    if n < 26
      LETTERS.fetch(n)
    else
      index_to_col_reference((n / 26) - 1) + index_to_col_reference(n % 26)
    end
  end

  def self.column_for_path(path)
    if path =~ /^note\/(.*)\/([0-9]+)\/(.*)$/
      note_type = $1.intern
      index = Integer($2)
      field = $3.intern

      note_jsonmodel = nil

      if MULTIPART_NOTES_OF_INTEREST.include?(note_type)
        note_jsonmodel = 'note_multipart'
      elsif SINGLEPART_NOTES_OF_INTEREST.include?(note_type)
        note_jsonmodel = 'note_singlepart'
      end

      raise "Column definition not found for #{path}" if note_jsonmodel.nil?

      column = if field == :content
                 NoteContentColumn.new(:note, note_type, note_jsonmodel)
               else
                 extra_note_fields_for_type(note_type).detect {|col| col.name.intern == field}
               end

      raise "Column definition not found for #{path}" unless column

      column = column.clone
      column.index = index
      column
    elsif path =~ /^([a-z-_]+)\/([0-9]+)\/(.*)$/
      property_name = $1.intern
      index = Integer($2)
      field = $3.intern

      column = FIELDS_OF_INTEREST.values.flatten.find {|col| col.name.intern == field && col.property_name.intern == property_name}

      raise "Column definition not found for #{path}" if column.nil?

      column = column.clone
      column.index = index

      column
    else
      column = FIELDS_OF_INTEREST.fetch(:archival_object).find {|col| col.name == path.intern}

      raise "Column definition not found for #{path}" if column.nil?

      column.clone
    end
  end

  class EnumMapper
    def self.enum_id_to_spreadsheet_value(enum_id, enum_name)
      return enum_id if enum_id.to_s.empty?

      enum_value = BackendEnumSource.value_for_id(enum_name, enum_id)

      EnumMapper.enum_to_spreadsheet_value(enum_value, enum_name)
    end

    def self.enum_to_spreadsheet_value(enum_value, enum_name)
      return enum_value if enum_value.to_s.empty?

      enum_label = I18n.t("enumerations.#{enum_name}.#{enum_value}", :default => enum_value)

      "#{enum_label} [#{enum_value}]"
    end

    def self.spreadsheet_value_to_enum(spreadsheet_value)
      return spreadsheet_value if spreadsheet_value.to_s.empty?

      if spreadsheet_value.to_s =~ /\[(.*)\]$/
        $1
      elsif raise "Could not parse enumeration value from: #{spreadsheet_value}"
      end
    end
  end

  def self.related_accessions_enabled?
    Object.const_defined?('Relationships::ArchivalObjectAccessionComponentLinks') && ArchivalObject.relationships.include?(Relationships::ArchivalObjectAccessionComponentLinks)
  end

  def self.note_jsonmodel_for_type(note_type)
    return 'note_multipart' if MULTIPART_NOTES_OF_INTEREST.include?(note_type.intern)
    return 'note_singlepart' if SINGLEPART_NOTES_OF_INTEREST.include?(note_type.intern)

    raise "Note type not supported: #{note_type}"
  end
end
