class AccessionInventoryReport < AbstractReport

  register_report

  def template
    'accession_inventory_report.erb'
  end

  def query
    db[:accession].
      select(Sequel.as(:id, :accessionId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:identifier, :accessionNumber),
             Sequel.as(:title, :title),
             Sequel.as(:accession_date, :accessionDate),
             Sequel.as(:inventory, :inventory),
             Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'inclusive\', 0)'), :dateExpression),
             Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'inclusive\', 1)'), :dateBegin),
             Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'inclusive\', 2)'), :dateEnd),
             Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'bulk\', 1)'), :bulkDateBegin),
             Sequel.as(Sequel.lit('GetAccessionDatePart(id, \'bulk\', 2)'), :bulkDateEnd),
             Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :containerSummary),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType)).
       filter(:repo_id => @repo_id)
       .where(Sequel.~(:inventory => nil))
  end

  # Accessions with Inventories
  def total_with_inventories
    @total_with_inventories ||= self.query.where(Sequel.~(:inventory => nil)).count
  end

end
