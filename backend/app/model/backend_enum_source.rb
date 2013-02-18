class BackendEnumSource

  def self.valid?(enum_name, value)
    if RequestContext.get(:create_enums)
      # The customer is always right!
      DB.open(true) do |db|
        enum_id = db[:enumeration].filter(:name => enum_name).select(:id).first[:id]

        raise "Couldn't find enum: #{enum_name}" if !enum_id

        DB.attempt {
          db[:enumeration_value].insert(:enumeration_id => enum_id,
                                        :value => value)
          Enumeration.broadcast_changes
        }.and_if_constraint_fails do
          # Must already be there.  No problem.
        end
      end
    end

    self.values_for(enum_name).include?(value)
  end


  def self.values_for(enum_name)
    DB.open(true) do |db|
      id = db[:enumeration].join(:enumeration_value, :enumeration_id => :id).
                            filter(:name => enum_name).
                            select(:value).all.map {|row| row[:value]}
    end
  end

end
