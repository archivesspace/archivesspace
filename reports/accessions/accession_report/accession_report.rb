class AccessionReport < AbstractReport

  register_report


  def query
    query_string = "SELECT `id` AS `accessionId`,
	`repo_id` AS `repo_id`,
	`identifier` AS `accessionNumber`,
	`title` AS `title`,
	`accession_date` AS `accessionDate`,
	GetAccessionExtent(id) AS `extentNumber`,
	GetAccessionExtentType(id) AS `extentType`,
	`general_note` AS `generalNote`,
	GetAccessionContainerSummary(id) AS `containerSummary`,
	GetAccessionDatePart(id, 'inclusive', 0) AS `dateExpression`,
	GetAccessionDatePart(id, 'inclusive', 1) AS `dateBegin`,
	GetAccessionDatePart(id, 'inclusive', 2) AS `dateEnd`,
	GetAccessionDatePart(id, 'bulk', 1) AS `bulkDateBegin`,
	GetAccessionDatePart(id, 'bulk', 2) AS `bulkDateEnd`,
	GetEnumValueUF(acquisition_type_id) AS `acquisitionType`,
	`retention_rule` AS `retentionRule`,
	`content_description` AS `descriptionNote`,
	`condition_description` AS `conditionNote`,
	`inventory` AS `inventory`,
	`disposition` AS `dispositionNote`,
	`restrictions_apply` AS `restrictionsApply`,
	`access_restrictions` AS `accessRestrictions`,
	`access_restrictions_note` AS `accessRestrictionsNote`,
	`use_restrictions` AS `useRestrictions`,
	`use_restrictions_note` AS `useRestrictionsNote`,
	GetAccessionRightsTransferred(id) AS `rightsTransferred`,
	GetAccessionRightsTransferredNote(id) AS `rightsTransferredNote`,
	GetAccessionAcknowledgementSent(id) AS `acknowledgementSent`
FROM `accession` WHERE repo_id=#{repo_id};"

    result = db.fetch(query_string)
    result.map(&:to_hash)
  end

end
