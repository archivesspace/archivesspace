module Representative

  # Handle the representative property for subrecords i.e. `is_representative`, `is_display_name`, `authorized`

  def before_validation
    super

    representative_for_types.keys.each do |property|
      self.send("#{property}=", nil) if self.send(property) != 1
    end
  end

  # Append _id to 'type' i.e. :resource -> :resource_id
  def representative_id_for_type(type)
    type.to_s.concat('_id').to_sym
  end

  # Example: { is_representative: [:digital_object] }
  def representative_for_types
    raise 'Not implemented'
  end

  def validate
    # property is the representative field i.e. `:is_representative`, `:is_display_name`, `:authorized`
    # records are symbols referring to (parent) record types the property applies to (i.e. :resource)
    representative_for_types.each do |property, records|
      next unless self.send(property) # bail if this property is not truthy

      records.each do |type|
        id_field = representative_id_for_type(type)
        validates_unique(
          [property, id_field],
          :message => "A #{type} can have only one #{self.class.name} defined as: #{property}"
        )
        map_validation_to_json_property([property, id_field], property)
      end
    end

    super
  end

end
