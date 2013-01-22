class BackendEnumSource

  def self.values_for(enum_name)
    DB.open(true) do |db|
      db[:enumerations].filter(:enum_name => enum_name).all.map {|row| row[:enum_value]}
    end
  end

end
