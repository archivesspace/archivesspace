class AccessionReport < AbstractReport

  register_report

  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end

  def template
    "accession_report.erb"
  end

  def headers
    query.columns.map(&:to_s)
  end

  def processor
    {
    }
  end

  def accession_count
    query.count
  end

  def query
    db[:accession]
      .select(Sequel.as(:id, :accessionId),
              Sequel.as(:repo_id, :repo_id),
              Sequel.as(:identifier, :accessionNumber),
              Sequel.as(:title, :title),
              Sequel.as(:accession_date, :accessionDate),
              Sequel.as(Sequel.lit("GetAccessionExtent(id)"), :extentNumber),
              Sequel.as(Sequel.lit("GetAccessionExtentType(id)"), :extentType),
              Sequel.as(:general_note, :generalNote),
              Sequel.as(Sequel.lit("GetAccessionContainerSummary(id)"), :containerSummary),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'inclusive', 0)"), :dateExpression),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'inclusive', 1)"), :dateBegin),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'inclusive', 2)"), :dateEnd),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'bulk', 1)"), :bulkDateBegin),
              Sequel.as(Sequel.lit("GetAccessionDatePart(id, 'bulk', 2)"), :bulkDateEnd),
              Sequel.as(Sequel.lit("GetEnumValueUF(acquisition_type_id)"), :acquisitionType),
              Sequel.as(:retention_rule, :retentionRule),
              Sequel.as(:content_description, :descriptionNote),
              Sequel.as(:condition_description, :conditionNote),
              Sequel.as(:inventory, :inventory),
              Sequel.as(:disposition, :dispositionNote),
              Sequel.as(:restrictions_apply, :restrictionsApply),
              Sequel.as(:access_restrictions, :accessRestrictions),
              Sequel.as(:access_restrictions_note, :accessRestrictionsNote),
              Sequel.as(:use_restrictions, :useRestrictions),
              Sequel.as(:use_restrictions_note, :useRestrictionsNote),
              Sequel.as(Sequel.lit("GetAccessionRightsTransferred(id)"), :rightsTransferred),
              Sequel.as(Sequel.lit("GetAccessionRightsTransferredNote(id)"), :rightsTransferredNote),
              Sequel.as(Sequel.lit("GetAccessionAcknowledgementSent(id)"), :acknowledgementSent)).
        filter(:repo_id => @repo_id)
  end

end
