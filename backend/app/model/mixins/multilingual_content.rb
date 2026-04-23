module MultilingualContent

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Declares multilingual fields and overrides their Sequel column accessors
    # with language-aware getters and setters backed by the record's +_mlc+ table.
    #
    # @param fields [Array<Symbol, String>] names of the fields to make multilingual
    def set_multilingual_fields(*fields)
      @multilingual_fields = fields.map(&:to_sym)
      fields.each do |field|
        define_method(field) do
          get_field_value(field)
        end
        define_method(:"#{field}=") do |value|
          set_field_value(field, value)
        end
      end
    end

    # @return [Array<Symbol>] the multilingual field names declared on this model
    def get_multilingual_fields
      @multilingual_fields || []
    end

    # @return [Symbol] the name of the +_mlc+ table for this model
    def mlc_table
      :"#{table_name}_mlc"
    end

    # Deletes all rows in the +_mlc+ table for the given IDs before removing
    # the parent records, satisfying the foreign key constraint.
    def handle_delete(ids_to_delete)
      db[mlc_table].where(:"#{table_name}_id" => ids_to_delete).delete
      super
    end

    # Returns every +_mlc+ row for +obj+, keyed by
    # +"<language_iso639_2>_<script_iso15924>"+, stripped of the FK and enum
    # ID columns so only the translated field values remain.
    #
    # @param obj [Sequel::Model]
    # @return [Hash{String=>Hash{String=>String}}]
    def to_mlc_hash(obj)
      fk = :"#{table_name}_id"
      field_syms = get_multilingual_fields
      rows = db[mlc_table].where(fk => obj.id).all
      rows.each_with_object({}) do |row, acc|
        lang   = BackendEnumSource.value_for_id('language_iso639_2', row[:language_id])
        script = BackendEnumSource.value_for_id('script_iso15924',   row[:script_id])
        next unless lang && script
        acc["#{lang}_#{script}"] = field_syms.each_with_object({}) do |field, h|
          val = row[field]
          h[field.to_s] = val unless val.nil? || val.to_s.empty?
        end
      end
    end

    # Returns the language/script pair for +obj+'s primary
    # +LanguageAndScriptOfDescription+ entry, or +nil+ if the record has no
    # such association or none is marked primary.
    #
    # @param obj [Sequel::Model]
    # @return [Hash{Symbol=>Integer}, nil]
    def primary_description_language_for_record(obj)
      return nil unless associations.include?(:language_and_script_of_description)

      entry = obj.language_and_script_of_description.find { |ld| ld.is_primary == 1 }
      entry ? { language_id: entry[:language_id], script_id: entry[:script_id] } : nil
    end

    # Batch-attaches MLC data to a set of serialised +jsons+ for +objs+.
    #
    # For every record:
    #   1. Sets +json['mlc_fields']+ to the +to_mlc_hash+ structure so the
    #      indexer can emit +<field>_<lang>_mlc+ dynamic fields and walk every
    #      variant into +fullrecord+ / +fullrecord_published+.
    #   2. Overwrites each declared multilingual scalar on the json with the
    #      value from the record's primary +lang_descriptions+ row, fixing the
    #      indexer bug where scalars reflected whatever
    #      +RequestContext.description_language+ happened to resolve to
    #      (eng/Latn by default) rather than the record's primary language.
    #
    # Callers invoke this at the bottom of their +sequel_to_jsonmodel+ so the
    # returned JSONModels carry +mlc_fields+ in +@data+.  +mlc_fields+ is
    # declared in +abstract_archival_object+ and +accession+ schemas so it
    # survives +to_hash(:trusted)+.
    #
    # @param objs  [Array<Sequel::Model>]
    # @param jsons [Array<JSONModel>]
    # @return [Array<JSONModel>] the same +jsons+ passed in
    def attach_mlc_fields_to_jsons!(objs, jsons)
      return jsons if objs.empty?

      fk           = :"#{table_name}_id"
      field_syms   = get_multilingual_fields
      rows_by_obj  = db[mlc_table].where(fk => objs.map(&:id)).all.group_by { |r| r[fk] }
      primary_map  = batch_primary_languages(objs)

      objs.zip(jsons).each do |obj, json|
        obj_rows = rows_by_obj.fetch(obj.id, [])

        json['mlc_fields'] = obj_rows.each_with_object({}) do |row, acc|
          lang   = BackendEnumSource.value_for_id('language_iso639_2', row[:language_id])
          script = BackendEnumSource.value_for_id('script_iso15924',   row[:script_id])
          next unless lang && script
          acc["#{lang}_#{script}"] = field_syms.each_with_object({}) do |field, h|
            val = row[field]
            h[field.to_s] = val unless val.nil? || val.to_s.empty?
          end
        end

        primary = primary_map[obj.id]
        next unless primary
        primary_row = obj_rows.find { |r|
          r[:language_id] == primary[:language_id] && r[:script_id] == primary[:script_id]
        }
        next unless primary_row
        field_syms.each do |field|
          val = primary_row[field]
          json[field.to_s] = val unless val.nil?
        end
      end

      jsons
    end

    # Returns +{obj_id => {language_id:, script_id:}}+ for each obj that has
    # a primary +language_and_script_of_description+ row, using a single
    # batched SELECT.  Empty when the model has no such association.
    def batch_primary_languages(objs)
      return {} if objs.empty?
      return {} unless associations.include?(:language_and_script_of_description)

      fk = :"#{table_name}_id"
      db[:language_and_script_of_description]
        .where(fk => objs.map(&:id), :is_primary => 1)
        .select(fk, :language_id, :script_id)
        .each_with_object({}) do |row, h|
          h[row[fk]] = { language_id: row[:language_id], script_id: row[:script_id] }
        end
    end
  end

  # Returns the value of +field_name+ for the current language context,
  # falling back to the primary language, then to the configured
  # +AppConfig[:mlc_default_language]+ / +AppConfig[:mlc_default_script]+.
  #
  # @param field_name [Symbol, String] the multilingual field to read
  # @return [String, nil] the field value, or +nil+ if no matching row exists
  def get_field_value(field_name)
    # For new (unsaved) records, values are buffered in @_mlc_pending — read
    # from there so that validation sees the in-flight value before the first save.
    if @_mlc_pending&.key?(field_name.to_sym)
      return @_mlc_pending[field_name.to_sym]
    end

    lang = RequestContext.description_language
    return nil unless lang
    row = db_mlc_table.where(
      :"#{self.class.table_name}_id" => id,
      :language_id => lang[:language_id],
      :script_id   => lang[:script_id]
    ).first
    row ? row[field_name.to_sym] : nil
  end

  # Upserts +value+ into the +_mlc+ table for +field_name+ under the current
  # language context, falling back to the primary language, then to the
  # configured +AppConfig[:mlc_default_language]+ / +AppConfig[:mlc_default_script]+.
  #
  # If the record has not yet been persisted (id is nil), the value is buffered
  # and flushed to the database in +after_save+.
  #
  # @param field_name [Symbol, String] the multilingual field to write
  # @param value [String, nil] the value to store
  def set_field_value(field_name, value)
    if id.nil?
      @_mlc_pending ||= {}
      @_mlc_pending[field_name.to_sym] = value
      return
    end

    lang = RequestContext.description_language
    return unless lang
    fk = :"#{self.class.table_name}_id"
    existing = db_mlc_table.where(
      fk           => id,
      :language_id => lang[:language_id],
      :script_id   => lang[:script_id]
    )
    if existing.count > 0
      existing.update(field_name.to_sym => value)
    else
      db_mlc_table.insert(
        fk                 => id,
        :language_id       => lang[:language_id],
        :script_id         => lang[:script_id],
        field_name.to_sym  => value
      )
    end
  end

  # Flushes any field values buffered before the record was first saved.
  def after_save
    return unless @_mlc_pending
    @_mlc_pending.each { |field_name, value| set_field_value(field_name, value) }
    @_mlc_pending = nil
  end

  # Overrides Sequel's raw column reader so that +record[:title]+ is equivalent
  # to +record.title+ for multilingual fields.
  #
  # @param column [Symbol, String]
  # @return [Object]
  def [](column)
    return get_field_value(column) if self.class.get_multilingual_fields.include?(column.to_sym)
    super
  end

  # Overrides Sequel's raw column writer so that +record[:title] = "foo"+ is
  # equivalent to +record.title = "foo"+ for multilingual fields.
  #
  # @param column [Symbol, String]
  # @param value [Object]
  def []=(column, value)
    return set_field_value(column, value) if self.class.get_multilingual_fields.include?(column.to_sym)
    super
  end

  # Overrides Sequel's +values+ hash to include multilingual fields sourced
  # from the +_mlc+ table.  This ensures that code which reads +obj.values+
  # directly (e.g. +NestedRecordResolver+) sees the correct field values.
  #
  # @return [Hash]
  def values
    mlc_values = self.class.get_multilingual_fields.each_with_object({}) do |field, h|
      h[field] = get_field_value(field)
    end
    super.merge(mlc_values)
  end

  private

  def db_mlc_table
    self.class.db[self.class.mlc_table]
  end

  # Returns the language/script pair for the record's primary
  # +LanguageAndScriptOfDescription+ entry, or +nil+ if none is marked primary.
  # Result is memoised on the instance.
  #
  # @return [Hash{Symbol=>Integer}, nil] +{ language_id:, script_id: }+, or +nil+
  def primary_description_language
    return @_primary_lang if defined?(@_primary_lang)
    if respond_to?(:language_and_script_of_description)
      entry = language_and_script_of_description.find { |ld| ld.is_primary == 1 }
      @_primary_lang = entry ? {language_id: entry[:language_id], script_id: entry[:script_id]} : nil
    else
      @_primary_lang = nil
    end
  end
end
