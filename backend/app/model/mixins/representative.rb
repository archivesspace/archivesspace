module Representative

  # Handle the `is_representative` property for records

  def before_validation
    super

    self.is_representative = nil if self.is_representative != 1
  end

  # Append _id to 'type' i.e. :resource -> :resource_id
  def representative_id_for_type(type)
    type.to_s.concat('_id').to_sym
  end

  # An array of record types (as symbols) used for uniqueness validation i.e. [:resource]
  # this needs to be implemented by the including class
  def representative_for_types
    raise 'Not implemented'
  end

  def validate
    return unless is_representative

    representative_for_types.each do |type|
      id_field = representative_id_for_type(type)
      validates_unique([:is_representative, id_field],
        :message => "A #{type} can only have one representative instance")
      map_validation_to_json_property([:is_representative, id_field], :is_representative)
    end
  end

end
