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

    info[:scoped_by_date_range] = "#{@from} & #{@to}"
  end

  def query
    results = db.fetch(query_string)
    info[:total_count] = results.count
    results
  end

  def query_string
    "select
      identifier as accession_number,
      title as record_title,
      accession_date
    from accession
    where accession_date > #{db.literal(@from.split(' ')[0].gsub('-', ''))} 
      and accession_date < #{db.literal(@to.split(' ')[0].gsub('-', ''))}
      and repo_id = #{db.literal(@repo_id)}
    order by accession_date"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
  end

  def identifier_field
    :accession_number
  end

  def page_break
    false
  end
end
