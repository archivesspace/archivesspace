module ASUtils

  def self.keys_as_strings(hash)
    result = {}

    hash.each do |key, value|
      result[key.to_s] = value
    end

    result
  end

end
