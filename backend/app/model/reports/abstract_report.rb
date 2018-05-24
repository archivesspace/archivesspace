require_relative 'report_manager'
require 'erb'

class AbstractReport
  include ReportManager::Mixin

  attr_accessor :repo_id
  attr_accessor :format
  attr_accessor :params
  attr_accessor :db
  attr_accessor :job
  attr_accessor :info
  attr_accessor :template

  def initialize(params, job, db)
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ''
    @format = params[:format] if params.has_key?(:format) && params[:format] != ''
    @params = params
    @db = db
    @job = job
    @info = hash.new
    @template = 'generic_listing.erb'
  end

  def title
    I18n.t("reports.#{code}.title", :default => code)
  end

  def get_binding
    binding
  end

  def report
    self
  end

  def layout
    AppConfig[:report_page_layout]
  end

  def orientation
    "portrait"
  end

  def current_user
    @job.owner
  end

  def query(db = @db)
    raise 'Please specify a query to return your reportable results'
  end

  def generate(file)
    if format == 'json'
      generate_json(file)
    elsif format == 'html'
      generate_html(file)
    else
      generate_json(file)
    end
  end

  def generate_json(file)
    json = ASUtils.to_json(query)
    file.write(json)
  end

  def generate_html(file)
    renderer = ERB.new(File.read(template))
    file.write(renderer.result)
  end

  def format_sub_report(name, contents)
    ''
  end

  def each
    results = query
    results.each
  end

  def identifier(record)
    nil
  end

  def self.code
    self.name.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end

end
