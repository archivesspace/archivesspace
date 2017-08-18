class AssessmentRatingReport < AbstractReport

  # Gives us each_slice, used below
  include Enumerable

  attr_reader :values_of_interest

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
  end

  def template
    'assessment_rating_report.erb'
  end

  def rating_name
    db[:assessment_attribute_definition].filter(:id => @rating_id).get(:label)
  end

  def query
    db[:assessment]
      .join(:assessment_attribute, :assessment_id => :assessment__id)
      .join(:assessment_rlshp, :assessment_id => :assessment_id)
      .join(:assessment_attribute_definition, :id => :assessment_attribute__assessment_attribute_definition_id)
      .filter(:assessment_attribute_definition__id => @rating_id)
      .filter(:assessment_attribute__value => @values_of_interest.map(&:to_s))
      .select(:assessment_attribute_definition__label,
              :assessment_attribute__value,
              :assessment__id,
              :assessment_rlshp__accession_id,
              :assessment_rlshp__resource_id,
              :assessment_rlshp__archival_object_id,
              :assessment_rlshp__digital_object_id)
      .order(:assessment__survey_begin)
  end

  LINKED_RECORD_TYPES = {
    'accession_id' => Accession,
    'resource_id' => Resource,
    'digital_object_id' => DigitalObject,
    'archival_object_id' => ArchivalObject
  }

  BATCH_SIZE = 50

  def each_record
    RequestContext.open(:repo_id => repo_id) do
      each_slice(BATCH_SIZE) do |slice|
        # Fetch the records in this batch by record type
        fetched_records = {}
        LINKED_RECORD_TYPES.each do |column, model|
          records = model.filter(:id => slice.map {|row| row[column]}.compact).all
          fetched_records[model] = Hash[records.map {|record| [record.id, record]}]
        end

        # Now emit each row with its linked record
        slice.each do |row|
          column, model = LINKED_RECORD_TYPES.find {|column, model| row[column]}

          linked_record = fetched_records[model][row[column]]

          yield(:assessment_id => row['id'],
                :linked_record_type => linked_record.class.my_jsonmodel.record_type,
                :linked_record => linked_record[:display_string] || linked_record[:title],
                :rating => row['value'])
        end
      end
    end
  end

end
