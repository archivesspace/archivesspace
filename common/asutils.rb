module ASUtils

  def self.keys_as_strings(hash)
    result = {}

    hash.each do |key, value|
      result[key.to_s] = value
    end

    result
  end


  def self.as_array(thing)
    return [] if thing.nil?
    thing.kind_of?(Array) ? thing : [thing]
  end


  def self.jsonmodels_to_hashes(elt)

    if elt.is_a?(JSONModel::JSONModelType)
      elt = elt.to_hash(:raw)
    end

    if elt.is_a?(Hash)
      Hash[elt.map {|k, v| [k, self.jsonmodels_to_hashes(v)]}]
    elsif elt.is_a?(Array)
      elt.map {|v| self.jsonmodels_to_hashes(v)}
    else
      elt
    end
  end


  def self.json_parse(s)
    JSON.parse(s, :max_nesting => false, :create_additions => false)
  end


  def self.to_json(obj, opts = {})
    if obj.respond_to?(:jsonize)
      obj.jsonize(opts.merge(:max_nesting => false))
    else
      obj.to_json(opts.merge(:max_nesting => false))
    end
  end


  def self.find_local_directories(base = nil)
    [File.join(File.dirname(__FILE__), ".."),
     java.lang.System.get_property("ASPACE_LAUNCHER_BASE"),
     java.lang.System.get_property("catalina.base")].
      reject { |dir| !Dir.exists?(dir) }.
      map { |dir| File.join(*[dir, "local", base].compact) }
  end


  def self.extract_nested_strings(coll)
    if coll.is_a?(Hash)
      coll.values.map {|v| self.extract_nested_strings(v)}.flatten.compact
    elsif coll.is_a?(Array)
      coll.map {|v| self.extract_nested_strings(v)}.flatten.compact
    else
      coll
    end
  end

end
