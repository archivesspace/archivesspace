class AssessmentAttributeDefinitions < JSONModel(:assessment_attribute_definitions)

  def repo_formats
    attributes_for_type('format', false);
  end

  def repo_ratings
    attributes_for_type('rating', false);
  end

  def repo_conservation_issues
    attributes_for_type('conservation_issue', false);
  end

  def global_formats
    attributes_for_type('format', true);
  end

  def global_ratings
    attributes_for_type('rating', true);
  end

  def global_conservation_issues
    attributes_for_type('conservation_issue', true);
  end

  def repo_formats=(formats)
    set_repo_attributes_for_type('format', formats)
  end

  def repo_ratings=(ratings)
    set_repo_attributes_for_type('rating', ratings)
  end

  def repo_conservation_issues=(conservation_issues)
    set_repo_attributes_for_type('conservation_issue', conservation_issues)
  end

  def label_for_id(id)
    attribute = definitions.find{|d| d['id'] == id}
    return "UKNOWN" if attribute.nil?

    attribute.fetch('label')
  end

  private

  def attributes_for_type(type, global)
    definitions.select{|d| d['type'] == type && d['global'] == global}
  end

  def set_repo_attributes_for_type(type, attributes)
    definitions.delete_if {|d| d['type'] == type && !d['global']}
    attributes.each_with_index do |attr, i|
      definitions << {
        'label' => attr.fetch('label', ''),
        'id' => attr['id'] ? attr['id'].to_i : nil,
        'type' => type,
        'global' => false,
        'position' => i,
      }
    end
  end

end