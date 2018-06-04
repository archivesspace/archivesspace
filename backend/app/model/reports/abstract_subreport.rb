require_relative '../../lib/reports/report_utils'

class AbstractSubreport

  attr_accessor :repo_id
  attr_accessor :db
  attr_accessor :job
  attr_accessor :format

  def initialize(parent_report)
    @repo_id = parent_report.repo_id
    @db = parent_report.db
    @job = parent_report.job
    @format = parent_report.format
  end

  def get
    array = []
    query.each do |result|
      row = result.to_hash
      fix_row(row)
      array.push(row)
    end
    if array.empty?
      nil
    else
      array.push(code) if format == 'pdf' || format == 'html'
      array
    end
  end

  def query
    raise 'Please specify a query to return your reportable results'
  end

  def fix_row(row); end

  def code
    self.class.code
  end

  def self.code
    self.name.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end
end