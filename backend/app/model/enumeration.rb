class Enumeration < Sequel::Model(:enumeration)

  include ASModel
  corresponds_to JSONModel(:enumeration)

  set_model_scope :global

  one_to_many :enumeration_value

  @enumeration_users = {}

  # Record the fact that 'model' uses 'enum_name'.
  def self.register_enumeration_user(definition, model)
    enum_name = definition[:uses_enum]
    @enumeration_users[enum_name] ||= []
    @enumeration_users[enum_name] << [definition, model]
  end


  def self.users_of(enum_name)
    @enumeration_users[enum_name]
  end


  # Find all database records that refer to the enumeration value identified by
  # 'source_id' and repoint them to 'destination_id'.
  def migrate(old_value, new_value)
    old_enum_value = self.enumeration_value.find {|val| val[:value] == old_value}
    new_enum_value = self.enumeration_value.find {|val| val[:value] == new_value}

    self.class.users_of(self.name).each do |definition, model|
      property_id = "#{definition[:property]}_id".intern
      model.filter(property_id => old_enum_value.id).update(property_id => new_enum_value.id,
                                                            :last_modified => Time.now)
    end

    old_enum_value.delete

    self.class.broadcast_changes
  end


  def self.apply_values(obj, json, opts = {})
    incoming_values = Array(json['values'])
    existing_values = obj.enumeration_value.map {|val| val[:value]}

    added_values = incoming_values - existing_values
    removed_values = existing_values - incoming_values

    added_values.each do |value|
      obj.add_enumeration_value(:value => value)
    end


    removed_values.each do |value|
      DB.attempt {
        EnumerationValue.filter(:enumeration_id => obj.id,
                                :value => value).delete
      }.and_if_constraint_fails {
        raise ConflictException.new("Can't delete a value that's in use: #{value}")
      }
    end

    broadcast_changes

    obj.refresh
    obj
  end


  def self.create_from_json(json, opts = {})
    self.apply_values(super, json, opts)
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    self.class.apply_values(super, json, opts)
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super
    json['values'] = obj.enumeration_value.map {|val| val[:value]}
    json
  end


  def self.broadcast_changes
    Notifications.notify("ENUMERATION_CHANGED")
  end


end
