require_relative 'report_manager'

class AbstractReport
  include ReportManager::Mixin
  
  attr_accessor :repo_id
  attr_accessor :format
  attr_accessor :params
  attr_accessor :db

  def initialize(params, job, db)
    # sanity check, please. 
    params = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ""
    @format = params[:format] if params.has_key?(:format) && params[:format] != "" 
    @params = params 
    @job = job
    @db = db
  end

  def get_binding
    binding
  end

  def title
    self.class.name
  end

  def report
    self
  end

  def template
    '_listing.erb'
  end

  def layout
    AppConfig[:report_page_layout]
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
end
