class AssessmentLinkedRecordsSubreport < AbstractSubreport

  def initialize(parent_report, assessment_id)
    super(parent_report)
    @assessment_id = assessment_id
  end

  def query_string
    "(select
      resource.id as record_id,
      'Resource' as linked_record_type,
      resource_mlc.title as record_title,
      resource.identifier as identifier
    from assessment_rlshp
      join resource on assessment_rlshp.resource_id = resource.id
      #{mlc_join('resource')}
    where assessment_rlshp.assessment_id = #{db.literal(@assessment_id)}
      #{suppressed_filter('resource')})

    union

    (select
      archival_object.id as record_id,
      'Archival Object' as linked_record_type,
      ifnull(archival_object_mlc.title, archival_object_mlc.display_string) as record_title,
      archival_object.component_id as identifier
    from assessment_rlshp
      join archival_object on assessment_rlshp.archival_object_id = archival_object.id
      join resource on archival_object.root_record_id = resource.id
      #{mlc_join('archival_object')}
    where assessment_rlshp.assessment_id = #{db.literal(@assessment_id)}
      #{suppressed_filter('archival_object')}
      #{suppressed_filter('resource')})

    union

    (select
      accession.id as record_id,
      'Accession' as linked_record_type,
      accession_mlc.title as record_title,
      accession.identifier as identifier
    from assessment_rlshp
      join accession on assessment_rlshp.accession_id = accession.id
      #{mlc_join('accession')}
    where assessment_rlshp.assessment_id = #{db.literal(@assessment_id)}
      #{suppressed_filter('accession')})

    union

    (select
      digital_object.id as record_id,
      'Digital Object' as linked_record_type,
      digital_object_mlc.title as record_title,
      digital_object.digital_object_id as identifier
    from assessment_rlshp
      join digital_object on assessment_rlshp.digital_object_id = digital_object.id
      #{mlc_join('digital_object')}
    where assessment_rlshp.assessment_id = #{db.literal(@assessment_id)}
      #{suppressed_filter('digital_object')})"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row) unless row[:linked_record_type].include?('Object')
    ReportUtils.fix_id(row)
  end

end
