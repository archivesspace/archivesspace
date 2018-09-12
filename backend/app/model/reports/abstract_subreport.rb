require_relative '../../lib/reports/report_utils'
require_relative 'custom_field'

class AbstractSubreport

  include CustomField::Mixin

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

  def get_content
    array = []
    query.each do |result|
      row = result.to_hash
      fix_row(row)
      array.push(row)
    end
    if array.empty?
      nil
    else
      array.push(code) if ['pdf', 'html', 'rtf'].include? format
      array
    end
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    raise 'Please specify a query string to return your reportable results'
  end

  def fix_row(row); end

  def code
    self.class.code
  end

  def self.code
    self.name.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end

  def self.field_name
    raise 'Must specify field_name in order to use in custom report.'
  end

  def self.translation_scope
    nil
  end
end