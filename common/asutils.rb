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
      elt = elt.to_hash(true)
    end

    if elt.is_a?(Hash)
      Hash[elt.map {|k, v| [k, self.jsonmodels_to_hashes(v)]}]
    elsif elt.is_a?(Array)
      elt.map {|v| self.jsonmodels_to_hashes(v)}
    else
      elt
    end
  end

end
