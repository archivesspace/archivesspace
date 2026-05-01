class RequestContext

  def self.active?
    !Thread.current[:request_context].nil?
  end


  def self.in_global_repo
    self.open(:repo_id => Repository.global_repo_id) do
      yield
    end
  end


  def self.open(context = {})
    # Stash the original context
    original_context = Thread.current[:request_context]

    # Add in the bits we care about
    Thread.current[:request_context] ||= {}
    Thread.current[:request_context] = Thread.current[:request_context].merge(context)

    begin
      yield
    ensure
      # And restore the old context once done
      Thread.current[:request_context] = original_context
    end
  end


  def self.put(key, val)
    Thread.current[:request_context][key] = val
  end


  def self.get(key)
    if Thread.current[:request_context]
      Thread.current[:request_context][key]
    end
  end


  def self.dump
    Thread.current[:request_context].clone
  end


  # Resolves the active language/script pair for MLC field lookups.
  #
  # Returns the language set on the current request context if present,
  # otherwise falls back to the enumeration IDs for
  # +AppConfig[:mlc_default_language]+ / +AppConfig[:mlc_default_script]+.
  #
  # @return Hash{Symbol=>Integer} +{ language_id:, script_id: }+
  def self.description_language
    lang = get(:language_of_description)
    return lang if lang

    resolved = resolve_language_pair(AppConfig[:mlc_default_language],
                                     AppConfig[:mlc_default_script])
    put(:language_of_description, resolved) if resolved && active?
    resolved
  end


  # Resolves a +(language_tag, script_tag)+ pair of ISO codes to the matching
  # +enumeration_value+ IDs.  Returns +nil+ if either tag is missing, empty, or
  # not present in the +language_iso639_2+ / +script_iso15924+ enumerations.
  #
  # @param language_tag [String, nil] ISO 639-2 code (e.g. +"eng"+)
  # @param script_tag [String, nil] ISO 15924 code (e.g. +"Latn"+)
  # @return [Hash{Symbol=>Integer}, nil] +{ language_id:, script_id: }+, or +nil+
  def self.resolve_language_pair(language_tag, script_tag)
    return nil if language_tag.nil? || language_tag.empty?
    return nil if script_tag.nil?   || script_tag.empty?

    lang_enum   = Enumeration.filter(:name => 'language_iso639_2').get(:id)
    script_enum = Enumeration.filter(:name => 'script_iso15924').get(:id)
    lang_id   = EnumerationValue.filter(:enumeration_id => lang_enum,   :value => language_tag).get(:id)
    script_id = EnumerationValue.filter(:enumeration_id => script_enum, :value => script_tag).get(:id)

    (lang_id && script_id) ? { language_id: lang_id, script_id: script_id } : nil
  end

end
