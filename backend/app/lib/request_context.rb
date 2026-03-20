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
  # @return [Hash{Symbol=>Integer}, nil] +{ language_id:, script_id: }+, or
  #   +nil+ if neither can be resolved.
  def self.description_language
    lang = get(:language_of_description)
    return lang if lang

    lang_enum   = Enumeration.filter(:name => 'language_iso639_2').get(:id)
    script_enum = Enumeration.filter(:name => 'script_iso15924').get(:id)
    lang_id   = EnumerationValue.filter(:enumeration_id => lang_enum,   :value => AppConfig[:mlc_default_language]).get(:id)
    script_id = EnumerationValue.filter(:enumeration_id => script_enum, :value => AppConfig[:mlc_default_script]).get(:id)

    resolved = (lang_id && script_id) ? { language_id: lang_id, script_id: script_id } : nil
    put(:language_of_description, resolved) if resolved && active?
    resolved
  end

end
