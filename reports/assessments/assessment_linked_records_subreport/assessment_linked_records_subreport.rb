class AssessmentLinkedRecordsSubreport < AbstractSubreport

  def initialize(parent_report, assessment_id)
    super(parent_report)
    @assessment_id = assessment_id
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    "(select
      'Resource' as linked_record_type,
      resource.title as record_title,
      resource.identifier as identifier
    from assessment_rlshp
      join resource on assessment_rlshp.resource_id = resource.id
    where assessment_rlshp.assessment_id = #{@assessment_id})

    union

    (select
      'Archival Object' as linked_record_type,
      ifnull(archival_object.title, archival_object.display_string) as record_title,
      resource.identifier as identifier
    from assessment_rlshp
      join archival_object on assessment_rlshp.archival_object_id = archival_object.id
      join resource on archival_object.root_record_id = resource.id
    where assessment_rlshp.assessment_id = #{@assessment_id})

    union

    (select
      'Accession' as linked_record_type,
      accession.title as record_title,
      accession.identifier as identifier
    from assessment_rlshp
      join accession on assessment_rlshp.accession_id = accession.id
    where assessment_rlshp.assessment_id = #{@assessment_id})

    union

    (select
      'Digital Object' as linked_record_type,
      digital_object.title as record_title,
      digital_object.digital_object_id as identifier
    from assessment_rlshp
      join digital_object on assessment_rlshp.digital_object_id = digital_object.id
    where assessment_rlshp.assessment_id = #{@assessment_id})"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row) unless row[:linked_record_type] == 'Digital Object'
  end

end
