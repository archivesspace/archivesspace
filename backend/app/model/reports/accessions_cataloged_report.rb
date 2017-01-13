class AccessionsCatalogedReport < AbstractReport

  register_report({
                    :uri_suffix => "accessions_cataloged_report",
                    :description => "Displays only those accessions that have been cataloged. Report contains accession number, linked resources, title, extent, cataloged, date processed, a count of the number of records selected that are checked as cataloged, and the total extent number for those records cataloged.",
                  })

  def title
    "Cataloged Accessions"
  end

  def template
    'accessions_cataloged_report.erb'
  end


  # <field name="accessionId" class="java.lang.Integer"/>
  # <field name="repo_id" class="java.lang.Integer">
  # <fieldDescription><![CDATA[]]></fieldDescription>
  # </field>
  # <field name="accessionNumber" class="java.lang.String"/>
  # <field name="title" class="java.lang.String">
  # <fieldDescription><![CDATA[]]></fieldDescription>
  # </field>
  # <field name="accessionDate" class="java.sql.Date"/>
  # <field name="accessionProcessed" class="java.lang.Boolean"/>
  # <field name="accessionProcessedDate" class="java.util.Date"/>
  # <field name="cataloged" class="java.lang.Boolean"/>
  # <field name="catalogedDate" class="java.util.Date"/>
  # <field name="extentNumber" class="java.math.BigDecimal"/>
  # <field name="extentType" class="java.lang.String"/>
  def headers
    ['accessionId', 'repo_id', 'accessionNumber', 'title', 'accessionDate',
     'accessionProcessed', 'accessionProcessedDate', 'cataloged', 'catalogedDate',
     'extentNumber', 'extentType']
  end

  def processor
    {
      'accessionId' => proc {|record| record[:accessionId]},
      'repo' => proc {|record| record[:repo]},
      'accessionNumber' => proc {|record| ASUtils.json_parse(record[:accessionNumber]).compact.join('.')},
      'title' => proc {|record| record[:title]},
      'accessionDate' => proc {|record| record[:accessionDate].nil? ? '' : record[:accessionDate].strftime("%Y-%m-%d")},
      'accessionProcessed' => proc {|record| record[:accessionProcessed]},
      'accessionProcessedDate' => proc {|record| record[:accessionProcessedDate].nil? ? '' : record[:accessionProcessedDate].strftime("%Y-%m-%d")},
      'cataloged' => proc {|record| record[:cataloged]},
      'catalogedDate' => proc {|record| record[:catalogedDate].nil? ? '' : record[:catalogedDate].strftime("%Y-%m-%d")},
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
             Sequel.as(Sequel.lit('GetAccessionProcessed(id)'), :accessionProcessed),
             Sequel.as(Sequel.lit('GetAccessionProcessedDate(id)'), :accessionProcessedDate),
             Sequel.as(Sequel.lit('GetAccessionCataloged(id)'), :cataloged),
             Sequel.as(Sequel.lit('GetAccessionCatalogedDate(id)'), :catalogedDate),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end


  # TODO: subreport for linked resources

  # Number of Records Reviewed
  def total_count
    @totalCount ||= self.query.count
  end

  # Cataloged Accessions
  def cataloged_count
    @catalogedCount ||= db.from(self.query).where(:cataloged => 1).count
  end

  # Total Extent of Cataloged Accessions
  def total_extent
    @totalExtent ||= db.from(self.query).where(:cataloged => 1).sum(:extentNumber)
  end
end
