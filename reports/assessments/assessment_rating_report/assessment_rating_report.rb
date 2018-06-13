require 'csv'

class AssessmentRatingReport < AbstractReport

  # Gives us each_slice, used below
  include Enumerable

  register_report({
                    :params => [["from", Date, "The start of report range"],
                                ["to", Date, "The start of report range"],
                                ["rating", "Rating", "The assessment rating to report on"],
                                ["values", "RatingValues", "The assessment rating values to include"]]
                  })

  def initialize(params, job, db)
    super

    @rating_id = Integer(params.fetch('rating'))
    @values_of_interest = params.keys.map {|key|
      if key =~ /\Avalue_[0-9]+\z/ && params[key] == 'on'
        # Don't really need integers but it's a decent sanitization step.
        Integer(key.split(/_/)[1])
      else
        nil
      end
    }.compact

    if @rating_id.nil? || @values_of_interest.empty?
      raise "Need a rating and at least one value of interest"
    end

    from = params["from"].to_s.empty? ? Time.at(0).to_s : params["from"]
    to = params["to"].to_s.empty? ? Time.parse('9999-01-01').to_s : params["to"]

    @from = DateTime.parse(from).to_time.strftime("%Y-%m-%d %H:%M:%S")
    @to = DateTime.parse(to).to_time.strftime("%Y-%m-%d %H:%M:%S")

    info[:scoped_by_rating] = get_attribute_name
    info[:showing_values] = @values_of_interest.join(', ')
    info[:scoped_by_date_range] = "#{@from} & #{@to}"
  end

  def get_attribute_name
    if info[:rating_name]
      name = info[:rating_name]
    else
      db.fetch("select label
               from assessment_attribute_definition
               where id = #{@rating_id}").each do |result|
        name = result[:label]
      end
    end
    name
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    "select
      null as linked_records,
      id,
      rating as rating_name,
      note as rating_note,
      general_assessment_note,
      surveyed_by,
      surveyed_extent,
      survey_begin,
      survey_end

    from assessment

      natural left outer join
      (select
        assessment_id as id,
        group_concat(name_person.sort_name separator ', ') as surveyed_by
      from surveyed_by_rlshp
        join agent_person on agent_person.id = surveyed_by_rlshp.agent_person_id
        join name_person on name_person.agent_person_id = agent_person.id  
      group by assessment_id) as surveyers
        
      natural join
      (select
        assessment_id as id,
        value as rating
      from assessment_attribute
      where assessment_attribute_definition_id = #{@rating_id}
        and value in (#{@values_of_interest.join(', ')})) as valid_ratings
            
      natural left outer join
      (select
        assessment_id as id,
        note
      from assessment_attribute_note
        where assessment_attribute_definition_id = #{@rating_id}) as notes

    where repo_id = #{@repo_id}
      and survey_begin > #{@from.split(' ')[0].gsub('-', '')} 
      and survey_begin < #{@to.split(' ')[0].gsub('-', '')}"
  end

  def fix_row(row)
    row[:linked_records] = AssessmentLinkedRecordsSubreport.new(self, row[:id])
                                                           .get_content
  end

  def special_translation(key)
    if key == :rating_name
      get_attribute_name
    else
      nil
    end
  end

  def identifier_field
    :id
  end

end
