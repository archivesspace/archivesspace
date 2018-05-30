require_relative 'report_manager'
require_relative '../../lib/reports/report_utils'
require 'erb'

class AbstractReport
  include ReportManager::Mixin

  attr_accessor :repo_id
  attr_accessor :format
  attr_accessor :params
  attr_accessor :db
  attr_accessor :job
  attr_accessor :info

  def initialize(params, job, db)
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ''
    @format = params[:format] if params.has_key?(:format) && params[:format] != ''
    @params = params
    @db = db
    @job = job
    @info = {}
  end

  def title
    I18n.t("reports.#{code}.title", :default => code)
  end

  def layout
    AppConfig[:report_page_layout]
  end

  # def orientation
  #   "portrait"
  # end

  def current_user
    @job.owner
  end

  def query(db = @db)
    raise 'Please specify a query to return your reportable results'
  end

  def code
    self.class.code
  end

  def self.code
    self.name.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end

  def identifier(record)
    nil
  end

end
