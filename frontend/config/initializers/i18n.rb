module I18n
  def self.try_really_hard_to_find_a_key(exception, locale, key, opts)

    substitutions = [[/\[\]/, ""],
                     [/\/[0-9]+\//, "."],
                     [/\]/, ""],
                     [/\[/, "."]]

    new_key = key.to_s
    substitutions.each do |pattern, replacement|
      new_key = new_key.gsub(pattern, replacement)
    end

    if key.to_s != new_key
      return translate(new_key.intern, opts.merge(:locale => locale))
    end

    ExceptionHandler.new.call(exception, locale, key, opts)
  end
end

I18n.exception_handler = :try_really_hard_to_find_a_key
