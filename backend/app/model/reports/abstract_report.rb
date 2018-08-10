require_relative 'report_manager'
require_relative '../../lib/reports/report_utils'
require 'erb'

class AbstractReport
  include ReportManager::Mixin
  include JSONModel

  attr_accessor :repo_id
  attr_accessor :format
  attr_accessor :params
  attr_accessor :db
  attr_accessor :job
  attr_accessor :info
  attr_accessor :page_break
  attr_accessor :expand_csv

  def initialize(params, job, db)
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ''
    @format = params[:format] if params.has_key?(:format) && params[:format] != ''
    @expand_csv = !(params.has_key?('csv_show_json') ? params['csv_show_json'] : false)
    @params = params
    @db = db
    @job = job
    @info = {}
  end

  def page_break
    true
  end

  def title
    I18n.t("reports.#{code}.title", :default => code)
  end

  def orientation
    'portrait'
  end

  def layout
    AppConfig[:report_page_layout]
  end

  def current_user
    @job.owner
  end

  def get_content
    array = []
    query.each do |result|
      row = result.to_hash
      fix_row(row)
      array.push(row)
    end
    info[:repository] = repository
    after_tasks
    array
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    raise 'Please specify a query string to return your reportable results'
  end

  def fix_row(row); end

  def after_tasks; end

  def code
    self.class.code
  end

  def self.code
    self.name.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end

  def identifier_field
    nil
  end

  def repository
    Repository.get_or_die(repo_id).name
  end

  def special_translation(key, subreport_code)
    nil
  end
end
