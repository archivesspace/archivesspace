class AccessionReport < AbstractReport
  register_report

  def fix_row(row)
    clean_row(row)
    add_sub_reports(row)
  end

  def query
    results = db.fetch(query_string)
    info[:number_of_accessions] = results.count
    results
  end

  def query_string
    "select
	id as accession_id,
	identifier as accession_number,
    title as accession_title,
    accession_date as accession_date,
    extent_number,
    extent_type,
    general_note,
    container_summary,
    date_expression,
    begin_date,
    end_date,
    bulk_begin_date,
    bulk_end_date,
    acquisition_type,
    retention_rule,
    content_description as description_note,
    condition_description as condition_note,
    inventory,
    disposition as disposition_note,
    restrictions_apply,
    access_restrictions,
    access_restrictions_note,
    use_restrictions,
    use_restrictions_note,
    ifnull(rights_transferred, false) as rights_transferred,
    rights_transferred_note,
    ifnull(acknowledgement_sent, false) as acknowledgement_sent
from accession natural join

	(select
		accession_id as id,
		sum(number) as extent_number,
		GROUP_CONCAT(distinct enumeration_value.value SEPARATOR ', ') as extent_type,
		GROUP_CONCAT(distinct extent.container_summary SEPARATOR ', ') as container_summary
	from extent, enumeration_value
	where enumeration_value.id = extent.extent_type_id
	group by accession_id) as extent_cnt

	natural left outer join
	(select
		accession_id as id,
		group_concat(distinct expression separator ', ') as date_expression,
		group_concat(distinct begin separator ', ') as begin_date,
		group_concat(distinct end separator ', ') as end_date
	from date, enumeration_value
	where date.date_type_id = enumeration_value.id and enumeration_value.value = 'inclusive'
	group by accession_id) as inclusive_date

	natural left outer join
	(select
		accession_id as id,
		group_concat(distinct begin separator ', ') as bulk_begin_date,
		group_concat(distinct end separator ', ') as bulk_end_date
		from date, enumeration_value
		where date.date_type_id = enumeration_value.id and enumeration_value.value = 'bulk'
		group by accession_id) as bulk_date

	natural left outer join
	(select id as acquisition_type_id, value as acquisition_type from enumeration_value) as enum

	natural left outer join
	(select
		accession_id as id,
		count(*) != 0 as rights_transferred,
		group_concat(outcome_note separator ', ') as rights_transferred_note
	from event_link_rlshp, event, enumeration_value
	where event_link_rlshp.event_id = event.id
		and event.event_type_id = enumeration_value.id and enumeration_value.value = 'copyright_transfer'
	group by event_link_rlshp.accession_id) as rights_transferred

	natural left outer join
	(select
		accession_id as id,
		count(*) != 0 as acknowledgement_sent
	from event_link_rlshp, event, enumeration_value
	where event_link_rlshp.event_id = event.id
		and event.event_type_id = enumeration_value.id and enumeration_value.value = 'acknowledgement_sent'
	group by event_link_rlshp.accession_id) as acknowledgement_sent

where accession.repo_id = #{@repo_id}"
  end

  def clean_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_boolean_fields(row, %i[restrictions_apply
                                           access_restrictions use_restrictions
                                           rights_transferred
                                           acknowledgement_sent])
  end

  def add_sub_reports(row)
    id = row[:accession_id]
    row[:deaccessions] = AccessionDeaccessionsSubreport.new(self, id).get
    row[:locations] = AccessionLocationsSubreport.new(self, id).get
    row[:names] = AccessionNamesSubreport.new(self, id).get
    row[:subjects] = AccessionSubjectsSubreport.new(self, id).get
    row.delete(:accession_id)
  end

  def identifier_field
    :accession_number
  end
end
