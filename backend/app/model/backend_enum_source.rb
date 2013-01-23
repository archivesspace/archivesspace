class BackendEnumSource

  def self.values_for(enum_name)
    DB.open(true) do |db|
      id = db[:enumeration].join(:enumeration_value, :enumeration_id => :id).
                            filter(:name => enum_name).
                            select(:value).all.map {|row| row[:value]}
    end
  end

end
