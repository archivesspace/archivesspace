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
  end

  # Returns the value of +field_name+ for the current language context,
  # walking the MLC lookup chain (requested language → primary → AppConfig default).
  #
  # An explicit non-primary language request skips the primary/default
  # fallback, so untranslated fields read as blank rather than
  # prepopulating from the primary language.
  #
  # @param field_name [Symbol, String] the multilingual field to read
  # @return [String, nil] the field value, or +nil+ if no content exists anywhere
  def get_field_value(field_name)
    # For new (unsaved) records, values are buffered in @_mlc_pending — read
    # from there so that validation sees the in-flight value before the first save.
    if @_mlc_pending&.key?(field_name.to_sym)
      return @_mlc_pending[field_name.to_sym]
    end

    mlc_lookup_chain.each do |lang|
      row = mlc_row_for(lang[:language_id], lang[:script_id])
      value = row ? row[field_name.to_sym] : nil
      return value unless value.nil?
    end

    nil
  end

  # Upserts +value+ into the +_mlc+ table for +field_name+ under the current
  # language context, falling back to the primary language, then to the
  # configured +AppConfig[:mlc_default_language]+ / +AppConfig[:mlc_default_script]+.
  #
  # If the record has not yet been persisted (id is nil), the value is buffered
  # and flushed to the database in +apply_nested_records+, once the record's own
  # +lang_descriptions+ exist.
  #
  # @param field_name [Symbol, String] the multilingual field to write
  # @param value [String, nil] the value to store
  def set_field_value(field_name, value)
    if id.nil?
      @_mlc_pending ||= {}
      @_mlc_pending[field_name.to_sym] = value
      return
    end

    lang = mlc_write_language
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

    @_mlc_row_cache&.delete([lang[:language_id], lang[:script_id]])
  end

  # Applies nested records, then flushes any field values that were buffered
  # before the record's first save.
  def apply_nested_records(json, new_record = false)
    super
    # The primary language may have just been created by the nested records above.
    reset_mlc_memos
    flush_mlc_pending
  end

  # Drops memoised language state after a save so that later reads in the same
  # request reflect any change the save made.
  def after_save
    reset_mlc_memos
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

  # Ordered language/script pairs to try when reading a multilingual field.
  # An explicit non-primary request tries only that language, skipping the
  # primary/default fallback.
  def mlc_lookup_chain
    requested = RequestContext.requested_description_language
    primary   = primary_description_language

    if requested && requested != primary
      [requested]
    else
      [
        requested,                                     # 1. explicit request header / URL param
        primary,                                       # 2. record's own primary language
        RequestContext.default_description_language    # 3. AppConfig default (last resort)
      ].compact.uniq
    end
  end

  def mlc_write_language
    RequestContext.requested_description_language ||
      primary_description_language ||
      RequestContext.default_description_language
  end

  # Writes out values buffered while the record had no id yet.
  def flush_mlc_pending
    return unless @_mlc_pending
    pending = @_mlc_pending
    # Cleared before writing so that the writes below read through to the
    # database rather than seeing the buffer they are draining.
    @_mlc_pending = nil
    pending.each { |field_name, value| set_field_value(field_name, value) }
  end

  # Drops every memoised lookup that a save or a nested-record update can
  # invalidate.
  def reset_mlc_memos
    remove_instance_variable(:@_primary_lang) if defined?(@_primary_lang)
    @_mlc_row_cache = nil
    associations.delete(:language_and_script_of_description)
  end

  def db_mlc_table
    self.class.db[self.class.mlc_table]
  end

  # Fetches and caches the MLC row for a given language/script pair.
  # Multiple calls for the same pair within a request hit the DB only once.
  def mlc_row_for(language_id, script_id)
    @_mlc_row_cache ||= {}
    cache_key = [language_id, script_id]
    unless @_mlc_row_cache.key?(cache_key)
      @_mlc_row_cache[cache_key] = db_mlc_table.where(
        :"#{self.class.table_name}_id" => id,
        :language_id => language_id,
        :script_id   => script_id
      ).first
    end
    @_mlc_row_cache[cache_key]
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
