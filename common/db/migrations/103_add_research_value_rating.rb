require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:assessment) do
      drop_column(:research_value)
    end

    alter_table(:assessment_attribute_definition) do
      add_column(:readonly, Integer, :null => false, :default => 0)
    end

    self[:assessment_attribute_definition].insert(:repo_id => 1, :label => 'Research Value', :type => 'rating', :readonly => 1, :position => 7)

    interest_definition_id = self[:assessment_attribute_definition]
                               .filter(:type => 'rating')
                               .filter(:label => 'Interest')
                               .get(:id)

    quality_definition_id = self[:assessment_attribute_definition]
                              .filter(:type => 'rating')
                              .filter(:label => 'Documentation Quality')
                              .get(:id)

    research_value_id = self[:assessment_attribute_definition]
                          .filter(:type => 'rating')
                          .filter(:label => 'Research Value')
                          .get(:id)

    self[:assessment]
      .left_outer_join(:assessment_attribute,
                       {
                         :interest_attribute__assessment_id => :assessment__id,
                         :interest_attribute__assessment_attribute_definition_id => interest_definition_id
                       },
                       {
                         :table_alias => :interest_attribute
                       })
      .left_outer_join(:assessment_attribute,
                       {
                         :quality_attribute__assessment_id => :assessment__id,
                         :quality_attribute__assessment_attribute_definition_id => quality_definition_id
                       },
                       {
                         :table_alias => :quality_attribute
                       })
      .select(:assessment__id,
              Sequel.as(:interest_attribute__value, :interest_rating),
              Sequel.as(:quality_attribute__value, :quality_rating))
      .all
      .each do |row|

      research_value = (row[:interest_rating] || 0).to_i + (row[:quality_rating] || 0).to_i

      if research_value > 0
        self[:assessment_attribute].insert(:assessment_id => row[:id],
                                           :assessment_attribute_definition_id => research_value_id,
                                           :value => research_value)
      end
    end
  end

  down do
  end

end

