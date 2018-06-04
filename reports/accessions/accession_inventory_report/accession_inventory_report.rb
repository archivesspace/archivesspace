class AccessionInventoryReport < AbstractReport
  register_report

  def query
    array = []
    records = db[:accession]
              .select(Sequel.as(:id, :id),
                      Sequel.as(:identifier, :accession_number),
                      Sequel.as(:title, :accession_title),
                      Sequel.as(:accession_date, :accession_date),
                      Sequel.as(:inventory, :inventory),
                      Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'inclusive\', 0)'), :date_expression),
                      Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'inclusive\', 1)'), :begin_date),
                      Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'inclusive\', 2)'), :end_date),
                      Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'bulk\', 1)'), :bulk_begin_date),
                      Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'bulk\', 2)'), :bulk_end_date),
                      Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :container_summary),
                      Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extent_number),
                      Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extent_type))
              .filter(repo_id: @repo_id)
    info['number_of_records'] = records.count
    records.where(Sequel.~(inventory: nil)).each do |result|
      row = result.to_hash
      ReportUtils.fix_extent_format(row)
      ReportUtils.fix_identifier_format(row, :accession_number)
      row[:linked_resources] = AccessionResourcesSubreport.new(self, row[:id]).get
      row.delete(:id)
      array.push(row)
    end
    info['number_with_inventories'] = array.size
    array
  end

  def page_break
    false
  end
end
