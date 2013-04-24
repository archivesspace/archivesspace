module I18n

  INTERPOLATION_PATTERN = Regexp.union(
    /%%/,
    /%\{([[:word:]\.]+)\}/,                     # matches placeholders like "%{foo}" or "%{resource.title}"
    /%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps])/  # matches placeholders like "%<foo>.d"
  )

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


  def self.t(*args)
    self.t_raw(*args).html_safe
  end

  def self.t_raw(*args)
    self.translate(*args)
  end
end

I18n.exception_handler = :try_really_hard_to_find_a_key

class JSONModelI18nWrapper < Hash
  def to_s
    "JSONModelI18nWrapper: #{@mappings.inspect}"
  end

  def initialize(mappings)
    @mappings = mappings
    super()
  end

  def [](key)
    return if not key.to_s.include?(".")

    (object, property) = key.to_s.split(".", 2)

    CGI::escapeHTML(@mappings[object.intern][property])
  end

  def key?(key)
    return false if not key.to_s.include?(".")

    (object, property) = key.to_s.split(".", 2)

    @mappings.key?(object.intern) && @mappings[object.intern].has_key?(property)
  end

  def empty?
    @mappings.empty?
  end

end
