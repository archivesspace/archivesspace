class AssessmentSpecHelper
  def self.setup_global_attributes
    DB.open do |db|
      db[:assessment_attribute_definition].filter(:repo_id => 1).delete
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Global Rating", :type => "rating", :position => 0)
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Global Format", :type => "format", :position => 0)
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Global Conservation Issue", :type => "conservation_issue", :position => 0)
    end
  end

  def self.setup_research_value_ratings
    DB.open do |db|
      db[:assessment_attribute_definition].filter(:repo_id => 1).delete
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Interest", :type => "rating", :position => 0)
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Documentation Quality", :type => "rating", :position => 1)
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Research Value", :type => "rating", :position => 2, :readonly => 1)
    end
  end

  def self.setup_bad_definition
    DB.open do |db|
      db[:assessment_attribute_definition].filter(:repo_id => 1).delete
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Bad definition", :type => "bad type", :position => 0)
    end
  end


  def self.sample_definitions
    [
      {
        'label' => 'Global Rating',
        'type' => 'rating',
        'global' => true,
      },
      {
        'label' => 'Global Format',
        'type' => 'format',
        'global' => true,
      },
      {
        'label' => 'Global Conservation Issue',
        'type' => 'conservation_issue',
        'global' => true,
      },
      {
        'label' => 'Rating 1',
        'type' => 'rating',
      },
      {
        'label' => 'Rating 2',
        'type' => 'rating',
      },
      {
        'label' => 'Format 1',
        'type' => 'format',
      },
      {
        'label' => 'Format 2',
        'type' => 'format',
      },
      {
        'label' => 'Conservation Issue 1',
        'type' => 'conservation_issue',
      },
      {
        'label' => 'Conservation Issue 2',
        'type' => 'conservation_issue',
      }
    ]
  end
end
