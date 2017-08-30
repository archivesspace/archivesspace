require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:assessment) do
      add_column(:research_value, Integer, :null => false, :default => 0)
    end


    interest_definition_id = self[:assessment_attribute_definition]
                              .filter(:type => 'rating')
                              .filter(:label => 'Interest')
                              .select(:id)
                              .first
                              .fetch(:id)

    quality_definition_id = self[:assessment_attribute_definition]
                             .filter(:type => 'rating')
                             .filter(:label => 'Documentation Quality')
                             .select(:id)
                             .first
                             .fetch(:id)
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
        self[:assessment]
          .filter(:id => row[:id])
          .update(:research_value => research_value)
      end
    end
  end


  down do
  end

end

