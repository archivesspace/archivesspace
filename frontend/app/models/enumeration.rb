class Enumeration
  attr_accessor :enum_name
  attr_accessor :enum_value

  def initialize(hash = {})
    if hash
      @enum_name = hash["enum_name"]
      @enum_value = hash["enum_value"]
    end
  end
end
