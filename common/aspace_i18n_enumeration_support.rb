# Define a new :t_raw method that knows how to handle ArchivesSpace-specific
# enumeration translations.
#
# Called by both the ArchivesSpace backend and frontend, so avoid any Rails-isms
# here.

module I18n

  # can be used to reset the cache
  def self.initialize_cache
    @@translate_cache = java.util.concurrent.ConcurrentHashMap.new(TRANSLATE_CACHE_LIMIT)
  end

  TRANSLATE_CACHE_LIMIT = 8192
  @@translate_cache = initialize_cache
  ENUM_SEPARATOR = "\0"

  # Caching layer.  See #t_raw_uncached for the real action.
  def self.t_raw(*args)
    cache_key = build_cache_key(args)

    if !cache_key
      # This entry is uncacheable.  Perhaps because it contains placeholders to
      # be substituted.

      return self.t_raw_uncached(*args)
    end

    # prefix the generated cache key with the locale set per request cycle
    cache_key = "#{config.locale}.#{cache_key}"
    entry = nil
    cache_hit = false

    if (entry = @@translate_cache[cache_key])
      cache_hit = true
    else
      begin
        entry = [:result, self.t_raw_uncached(*args)]
      rescue
        entry = [:error, $!]
      end
    end

    if !cache_hit && @@translate_cache.size < TRANSLATE_CACHE_LIMIT
      # This won't strictly prevent the cache growing a bit larger than the
      # limit since the size check isn't performed under a lock, but should stop
      # unbounded growth due to bugs in code.
      @@translate_cache[cache_key] = entry
    end

    # TEST MODE
    # if cache_hit && entry[0] == :result
    #   raise args.inspect unless entry[1] == self.t_raw_uncached(*args)
    # end

    if entry[0] == :result
      return entry[1]
    else
      # Error
      raise entry[1]
    end
  end

  def self.t_raw_uncached(*args)
    key = args[0]

    default = if args[1].is_a?(String)
                args[1]
              else
                (args[1] || {}).fetch(:default, "")
              end

    # String
    if key && key.is_a?(String) && key.end_with?(".")
      return default
    end

    # Hash / Enumeration Value
    if key && key.is_a?(Hash) && key.has_key?(:enumeration)
      backend  = config.backend
      locale   = config.locale

      translation = backend.send(:lookup, locale, self.build_enumeration_key(key), [], {:separator => ENUM_SEPARATOR}) || default

      if translation && !translation.empty?
        return translation
      end
    end

    self.translate(key, **args[1])
  end

  def self.build_cache_key(args)
    key = args[0]

    # We'll only cache the trivial case: simple string lookup.  No placeholders.
    cacheable = (args[1] &&
                 args[1].class == Hash &&
                 args[1].keys.sort == [:default, :raise])

    if !cacheable
      return nil
    end

    if key.is_a?(Hash) && key.has_key?(:enumeration)
      self.build_enumeration_key(key)
    else
      key
    end
  end

  def self.build_enumeration_key(key)
    # Null character to cope with enumeration values containing dots.  Eugh.
    ['enumerations', key[:enumeration], key[:value]].join(ENUM_SEPARATOR)
  end

end
