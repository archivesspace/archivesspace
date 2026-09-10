module OAISetNames

  def validate_set_name(other_set_model)
    validates_unique(:set_name, :message => 'oai_set_name_unique')

    return if self.set_name.nil?

    if BackendEnumSource.values_for('archival_record_level').include?(self.set_name)
      errors.add(:set_name, 'oai_set_name_matches_level')
    end

    if other_set_model.where(:set_name => self.set_name).count > 0
      errors.add(:set_name, 'oai_set_name_unique')
    end
  end

end
