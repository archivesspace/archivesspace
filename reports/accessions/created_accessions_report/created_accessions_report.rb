class CreatedAccessionsReport < AbstractReport
  register_report(
    params: [['from', Date, 'The start of report range'],
             ['to', Date, 'The start of report range']]
  )

  def initialize(params, job, db)
    super

    from = params['from'] || Time.now.to_s
    to = params['to'] || Time.now.to_s

    @from = DateTime.parse(from).to_time.strftime('%Y-%m-%d %H:%M:%S')
    @to = DateTime.parse(to).to_time.strftime('%Y-%m-%d %H:%M:%S')

    info['created_between'] = "#{from} - #{to}"
  end

  def query
    db[:accession].where(accession_date: (@from..@to))
                  .order(Sequel.asc(:accession_date))
                  .filter(repo_id: @repo_id)
                  .select(Sequel.as(:identifier, :accession_number),
                          Sequel.as(:title, :accession_title),
                          Sequel.as(:accession_date, :accession_date),
                          Sequel.as(:create_time, :create_time))
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
  end

  def identifier_field
    :identifier
  end

  def page_break
    false
  end
end
