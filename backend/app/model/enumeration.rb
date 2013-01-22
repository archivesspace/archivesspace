class Enumeration < Sequel::Model(:enumerations)

  @enumeration_users = {}

  # Record the fact that 'model' uses 'enum_name'.
  def self.register_enumeration_user(definition, model)
    enum_name = definition[:uses_enum]
    @enumeration_users[enum_name] ||= []
    @enumeration_users[enum_name] << [definition, model]
  end


  # Find all database records that refer to the enumeration identified by
  # 'source_id' and repoint them to 'destination_id'.
  def self.migrate(source_id, target_id)
    src = self[source_id]
    target = self[target_id]

    if src.enum_name != target.enum_name
      raise "Can't migrate records from between enumerations (from #{src.enum_name} to #{target.enum_name})"
    end

    @enumeration_users[src.enum_name].each do |definition, model|
      property_id = "#{definition[:property]}_id".intern
      model.filter(property_id => src.id).update(property_id => target.id)
    end

    src.delete
  end


  def self.as_hash
    result = {}

    self.all.each do |row|
      result[row[:enum_name]] ||= []
      result[row[:enum_name]] << row[:enum_value]
    end

    result
  end

end
