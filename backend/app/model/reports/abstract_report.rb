require_relative 'report_manager'

class AbstractReport
  include ReportManager::Mixin

  def initialize(params)
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ""
  end

  def title
    self.class.name
  end

  def template
    :'reports/_listing'
  end

  def layout
    AppConfig[:report_page_layout]
  end

  def processor
    {}
  end

  def query(db)
    raise "Please specific a query to return your reportable results"
  end

  def scope_by_repo_id(dataset)
    dataset.where(:repo_id => @repo_id)
  end

  def each
    DB.open do |db|
      dataset = query(db)
      dataset = scope_by_repo_id(dataset) if @repo_id
      dataset.each do |row|
        yield(Hash[headers.map { |h|
          val = (processor.has_key?(h))?processor[h].call(row):row[h.intern]
          [h, val]
        }])
      end
    end
  end
end