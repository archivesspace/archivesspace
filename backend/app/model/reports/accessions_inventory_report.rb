class AccessionsInventoryReport < AbstractReport

  register_report({
                    :uri_suffix => "accessions_inventory_report",
                    :description => "Displays only those accession records with an inventory.  Report contains accession number, linked resources, title, extent, accession date, container summary, and inventory.",
                  })

  def title
    "Accessions with Inventories"
  end

  def template
    'accessions_inventory_report.erb'
  end

  def processor
    {
      'accessionId' => proc {|record| record[:accessionId]},
      'repo' => proc {|record| record[:repo]},
      'accessionNumber' => proc {|record| record[:accessionNumber]},
      'title' => proc {|record| record[:title]},
      'accessionDate' => proc {|record| record[:accessionDate]},
      'inventory' => proc {|record| record[:inventory]},
      'dateExpression' => proc {|record| record[:dateExpression]},
      'dateBegin' => proc {|record| record[:dateBegin]},
      'dateEnd' => proc {|record| record[:dateEnd]},
      'bulkDateBegin' => proc {|record| record[:bulkDateBegin]},
      'bulkDateEnd' => proc {|record| record[:bulkDateEnd]},
      'containerSummary' => proc {|record| record[:containerSummary]},
      'extentNumber' => proc {|record| record[:extentNumber]},
      'extentType' => proc {|record| record[:extentType]},
    }
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
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end

  # Number of Records Reviewed
  def total_count
    @total_count ||= self.query.count
  end

  # Accessions with Inventories
  def total_with_inventories
    @total_with_inventories ||= self.query.where(Sequel.~(:inventory => nil)).count
  end

end
