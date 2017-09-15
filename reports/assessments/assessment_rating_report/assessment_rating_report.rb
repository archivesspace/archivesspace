require 'csv'

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

    if @rating_id.nil? || @values_of_interest.empty?
      raise "Need a rating and at least one value of interest"
    end

    from = params["from"].to_s.empty? ? Time.at(0).to_s : params["from"]
    to = params["to"].to_s.empty? ? Time.parse('9999-01-01').to_s : params["to"]

    @from = DateTime.parse(from).to_time.strftime("%Y-%m-%d %H:%M:%S")
    @to = DateTime.parse(to).to_time.strftime("%Y-%m-%d %H:%M:%S")
  end

  def template
    'assessment_rating_report.erb'
  end

  def rating_name
    label, type = db[:assessment_attribute_definition].filter(:id => @rating_id).get([:label, :type])
    I18n.t("assessment_attribute.rating.#{label}", :default => label)
  end

  HEADERS = ['assessment_number', 'linked_record_type', 'linked_record_title', 'rating', 'rating_note', 'general_assessment_note', 'surveyors', 'surveyed_extent', 'survey_end']
  FIELDS = ['assessment_id', 'record_type', 'title', 'rating', 'rating_note', 'general_assessment_note', 'surveyors', 'surveyed_extent', 'survey_end']

  def orientation
    'landscape'
  end

  def to_a
    result = []

    renderer = ReportErbRenderer.new(self, {})

    each do |record|
      hash = {}

      record['surveyors'] = extract_surveyor_names(record['assessment_id']).join('; ')

      HEADERS.zip(FIELDS).each do |header, field|
        translated_header = renderer.t(header)

        if field == 'record_type'
          # We call .strip here because Derby seems to end up with a bunch of
          # padding on the literal string I gave it.  Maybe a Sequel bug?
          hash[translated_header] = I18n.t(record[field].strip + '._singular')
        elsif field == 'rating'
          hash[rating_name + ' ' + translated_header] = record[field]
        elsif field == 'rating_note'
          hash[rating_name + ' ' + translated_header] = record[field]
        else
          hash[translated_header] = record[field]
        end
      end

      result << hash
    end

    result
  end

  def to_json
    ASUtils.to_json(to_a)
  end

  def to_csv
    result = to_a

    return "" if result.empty?

    headers = result[0].keys

    CSV.generate do |csv|
      csv << headers

      result.each do |row|
        csv << headers.map {|header| row[header]}
      end
    end
  end

  def query
    base_query = db[:assessment]
                   .join(:assessment_attribute, :assessment_id => :assessment__id)
                   .join(:assessment_rlshp, :assessment_id => :assessment_id)
                   .join(:assessment_attribute_definition, :id => :assessment_attribute__assessment_attribute_definition_id)
                   .left_join(:assessment_attribute_note, :assessment_id => :assessment__id)
                   .filter(:assessment_attribute_definition__id => @rating_id)
                   .filter(:assessment_attribute__value => @values_of_interest.map(&:to_s))
                   .filter(Sequel.~(:assessment__inactive => 1))
                   .filter(:assessment__survey_begin => (@from..@to))


    base_selection = [
      Sequel.as(:assessment_attribute__value, :rating),
      Sequel.as(:assessment__id, :assessment_id),
      :assessment__survey_begin,
      :assessment__survey_end,
      Sequel.as(:assessment_attribute_note__note, :rating_note),
      :assessment__general_assessment_note,
      :assessment__surveyed_extent,
    ]

    accessions = base_query
                   .join(:accession, :id => :assessment_rlshp__accession_id)
                   .select(*(base_selection + [Sequel.as(:accession__display_string, :title),
                                               Sequel.as('accession', :record_type)]))

    resources = base_query
                   .join(:resource, :id => :assessment_rlshp__resource_id)
                   .select(*(base_selection + [Sequel.as(:resource__title, :title),
                                               Sequel.as('resource', :record_type)]))

    archival_objects = base_query
                   .join(:archival_object, :id => :assessment_rlshp__archival_object_id)
                   .select(*(base_selection + [Sequel.as(:archival_object__display_string, :title),
                                               Sequel.as('archival_object', :record_type)]))

    digital_objects = base_query
                        .join(:digital_object, :id => :assessment_rlshp__digital_object_id)
                        .select(*(base_selection + [Sequel.as(:digital_object__title, :title),
                                                    Sequel.as('digital_object', :record_type)]))


    accessions.union(resources, :all => true).union(archival_objects, :all => true).union(digital_objects, :all => true).order(Sequel.asc(Sequel.cast(:rating, Integer)), Sequel.asc(:assessment_id))
  end

  private

  def extract_surveyor_names(assessment_id)
    db[:surveyed_by_rlshp]
    .join(:agent_person, :agent_person__id => :surveyed_by_rlshp__agent_person_id)
    .join(:name_person, :name_person__agent_person_id => :agent_person__id)
    .filter(:surveyed_by_rlshp__assessment_id => assessment_id)
    .filter(:name_person__is_display_name => 1)
    .select(:sort_name)
    .map {|row| row[:sort_name] }
  end

end
