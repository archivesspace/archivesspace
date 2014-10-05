class Enumeration < Sequel::Model(:enumeration)

  include ASModel
  corresponds_to JSONModel(:enumeration)

  set_model_scope :global

  one_to_many :enumeration_value

  @enumeration_dependants = {}

  # Record the fact that 'model' uses 'enum_name'.
  def self.register_enumeration_dependant(definition, model)
    Array(definition[:uses_enum]).each do |enum_name|
      @enumeration_dependants[enum_name] ||= []
      @enumeration_dependants[enum_name] << [definition, model]
    end
  end


  def self.dependants_of(enum_name)
    @enumeration_dependants[enum_name]
  end


  # Find all database records that refer to the enumeration value identified by
  # 'source_id' and repoint them to 'destination_id'.
  def migrate(old_value, new_value)
    old_enum_value = self.enumeration_value.find {|val| val[:value] == old_value}

    if old_enum_value.readonly != 0
      raise AccessDeniedException.new("Can't transfer from a read-only enumeration value")
    end

    new_enum_value = self.enumeration_value.find {|val| val[:value] == new_value}

    self.class.dependants_of(self.name).each do |definition, model|
      property_id = "#{definition[:property]}_id".intern
      model.filter(property_id => old_enum_value.id).update(property_id => new_enum_value.id,
                                                            :system_mtime => Time.now)
    end

    old_enum_value.delete

    self.class.broadcast_changes
  end


  # Update the allowable values of the current enumeration.
  def self.apply_values(obj, json, opts = {})
    # don't allow update of an non-editable enumeration
    if not obj.editable
      raise AccessDeniedException.new("Cannot modify a non-editable enumeration: #{obj.name}")
    end

    incoming_values = Array(json['values'])
    existing_values = obj.enumeration_value.map {|val| val[:value]}

    added_values = incoming_values - existing_values
    removed_values = existing_values - incoming_values

    # Make sure we're not being asked to remove read-only values.
    if EnumerationValue.filter(:enumeration_id => obj.id,
                               :value => removed_values,
                               :readonly => 1).count > 0
      raise AccessDeniedException.new("Can't remove read-only enumeration values")
    end


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

    existing_default = obj.default_value.nil? ? nil : obj.default_value[:value]

    if opts[:default_value] != existing_default
      if opts[:default_value]
        new_default = EnumerationValue[:value => opts[:default_value]]
        return obj if new_default.nil? #just move along if the default isn't in the values table
        obj.default_value = new_default[:id]
      else
        obj.default_value = nil
      end

      obj.save
    end


    obj
  end


  def self.create_from_json(json, opts = {})
    default_value = json['default_value']
    json['default_value'] = nil

    self.apply_values(super, json, opts.merge({:default_value => default_value}))
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    default_value = json['default_value']
    json['default_value'] = nil

    self.class.apply_values(super, json, opts.merge({:default_value => default_value}))
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      values = obj.enumeration_value.map {|enum_value|
        {
          :value => enum_value[:value],
          :readonly => enum_value[:readonly]
        }
      }

      json['values'] = values.map {|v| v[:value]}
      json['readonly_values'] = values.map {|v| v[:value] if (v[:readonly] != 0)}.compact

      if obj.default_value
        json['default_value'] = EnumerationValue[:id => obj.default_value][:value]
      end
    end

    jsons
  end



  def self.broadcast_changes
    Notifications.notify("ENUMERATION_CHANGED")
  end


end
