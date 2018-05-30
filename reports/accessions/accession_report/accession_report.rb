class AccessionReport < AbstractReport

  register_report


  def query
    array = []
    results.each do |result|
      row = result.to_hash
      clean_row(row)
      add_sub_reports(row)
      array.push(row)
    end
    info[:number_of_accessions] = array.size
    array
  end

  def results
    db[:accession]
      .select(Sequel.as(:id, :accession_id),
              Sequel.as(:identifier, :accession_number),
              Sequel.as(:title, :accession_title),
              Sequel.as(:accession_date, :accession_date),
              Sequel.as(Sequel.lit("GetAccessionExtent(id)"), :extent_number),
              Sequel.as(Sequel.lit("GetAccessionExtentType(id)"), :extent_type),
              Sequel.as(:general_note, :general_note),
              Sequel.as(Sequel.lit("GetAccessionContainerSummary(id)"), :container_summary),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'inclusive', 0)"), :date_expression),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'inclusive', 1)"), :begin_date),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'inclusive', 2)"), :end_date),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'bulk', 1)"), :bulk_begin_date),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'bulk', 2)"), :bulk_end_date),
              Sequel.as(Sequel.lit("GetEnumValueUF(acquisition_type_id)"), :acquisition_type),
              Sequel.as(:retention_rule, :retention_rule),
              Sequel.as(:content_description, :description_note),
              Sequel.as(:condition_description, :condition_note),
              Sequel.as(:inventory, :inventory),
              Sequel.as(:disposition, :disposition_note),
              Sequel.as(:restrictions_apply, :restrictions_apply),
              Sequel.as(:access_restrictions, :access_restrictions),
              Sequel.as(:access_restrictions_note, :access_restrictions_note),
              Sequel.as(:use_restrictions, :use_restrictions),
              Sequel.as(:use_restrictions_note, :use_restrictions_note),
              Sequel.as(Sequel.lit("GetAccessionRightsTransferred(id)"), :rights_transferred),
              Sequel.as(Sequel.lit("GetAccessionRightsTransferredNote(id)"), :rights_transferred_note),
              Sequel.as(Sequel.lit("GetAccessionAcknowledgementSent(id)"), :acknowledgement_sent)).
      filter(repo_id: @repo_id).order(:accession_title)
  end

  def clean_row(row)
    ReportUtils.fix_identifer_format(row, :accession_number)
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_boolean_fields(row, %i[restrictions_apply
                                           access_restrictions use_restrictions
                                           rights_transferred
                                           acknowledgement_sent])
  end

  def add_sub_reports(row)
    id = row[:accession_id]
    row[:deaccessions] = AccessionDeaccessionsSubreport.new(self, id).query
    row[:locations] = AccessionLocationsSubreport.new(self, id).query
    row.delete(:accession_id)
  end

  def identifier(record)
    record[:accession_number]
  end

end
