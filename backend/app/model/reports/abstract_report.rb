require_relative 'report_manager'

class AbstractReport
  include ReportManager::Mixin

  attr_accessor :repo_id
  attr_accessor :format
  attr_accessor :params
  attr_accessor :db
  attr_reader :job

  def initialize(params, job, db)
    # sanity check, please.
    params = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ""
    @format = params[:format] if params.has_key?(:format) && params[:format] != ""
    @params = params
    @job = job
    @db = db
  end

  def title
    I18n.t("reports.#{code}.title", :default => code)
  end

  def new_subreport(subreport_model, params)
    subreport_model.new(params.merge(:format => 'html'), job, db)
  end

  def get_binding
    binding
  end

  def report
    self
  end

  def headers
    query.columns.map(&:to_s)
  end

  def template
    'generic_listing.erb'
  end

  def layout
    AppConfig[:report_page_layout]
  end

  def orientation
    "portrait"
  end

  def processor
    {}
  end

  def current_user
    @job.owner
  end

  def query(db = @db)
    raise "Please specify a query to return your reportable results"
  end

  def each(db = @db)
    dataset = query
    dataset.where(:repo_id => @repo_id) if @repo_id

    dataset.each do |row|
      yield(Hash[(headers + processor.keys).uniq.map { |h|
        val = (processor.has_key?(h))?processor[h].call(row):row[h.intern]
        [h, val]
      }])
    end
  end

  def code
    self.class.code
  end

  def self.code
    self.name.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end

  # Number of Records
  def total_count
    @total_count ||= self.query.count
  end

end
