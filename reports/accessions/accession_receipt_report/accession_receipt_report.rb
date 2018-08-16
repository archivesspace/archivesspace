class AccessionReceiptReport < AbstractReport
  register_report(
    params: [['scope_by_date', 'Boolean', 'Scope records by a date range'],
             ['from', Date, 'The start of report range'],
             ['to', Date, 'The start of report range']]
  )

  def initialize(params, job, db)
    super

    @date_scope = params['scope_by_date']

    if @date_scope
      from = params['from']
      to = params['to']

      raise 'Date range not specified.' if from === '' || to === ''

      @from = DateTime.parse(from).to_time.strftime('%Y-%m-%d %H:%M:%S')
      @to = DateTime.parse(to).to_time.strftime('%Y-%m-%d %H:%M:%S')

      info[:scoped_by_date_range] = "#{@from} & #{@to}"
    end
  end

  def query_string
    date_condition = if @date_scope
                      "accession_date > 
                      #{db.literal(@from.split(' ')[0].gsub('-', ''))} 
                      and accession_date < 
                      #{db.literal(@to.split(' ')[0].gsub('-', ''))}"
                    else
                      '1=1'
                    end
    "select
      id,
      identifier as accession_number,
      title as record_title,
      accession_date,
      container_summary,
      extent_number,
      extent_type
    from accession
      natural left outer join
        (select
          accession_id as id,
          sum(number) as extent_number,
          GROUP_CONCAT(distinct extent_type_id SEPARATOR ', ') as extent_type,
          GROUP_CONCAT(distinct extent.container_summary SEPARATOR ', ')
            as container_summary
        from extent
        group by accession_id) as extent_cnt
    where repo_id = #{db.literal(@repo_id)} and #{date_condition}"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    ReportUtils.get_enum_values(row, [:extent_type])
    ReportUtils.fix_extent_format(row)
    row[:names] = AccessionNamesSubreport.new(self, row[:id]).get_content
    row[:rights_statements] = AccessionRightsStatementSubreport.new(
      self, row[:id]).get_content
    row.delete(:id)
  end

  def identifier_field
    :accession_number
  end

end
