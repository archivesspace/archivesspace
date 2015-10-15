# Define a new :t_raw method that knows how to handle ArchivesSpace-specific
# enumeration translations.
#
# Called by both the ArchivesSpace backend and frontend, so avoid any Rails-isms
# here.

module I18n

  def self.t_raw(*args)
    key = args[0]
    default = if args[1].is_a?(String)
                args[1]
              else
                (args[1] || {}).fetch(:default, "")
              end

    # String
    if key && key.kind_of?(String) && key.end_with?(".")
      return default
    end

    # Hash / Enumeration Value
    if key && key.kind_of?(Hash) && key.has_key?(:enumeration)
      backend  = config.backend
      locale   = config.locale
      # Null character to cope with enumeration values containing dots.  Eugh.
      translation = backend.send(:lookup, locale, ['enumerations', key[:enumeration], key[:value]].join("\0"), [], {:separator => "\0"}) || default

      if translation && !translation.empty?
        return translation
      end
    end


    self.translate(*args)
  end

end
