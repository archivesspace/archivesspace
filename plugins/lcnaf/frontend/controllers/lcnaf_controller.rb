require 'opensearcher'
require 'securerandom'

class LcnafController < ApplicationController

  set_access_control "update_agent_record" => [:search, :index, :import]

  def index
    @page = 1
    @records_per_page = 10

    flash.now[:info] = I18n.t("plugins.lcnaf.messages.service_warning")
  end


  def search
    results = do_search(params)

    render :json => results.to_json
  end


  def import
    marcxml_file = searcher.results_to_marcxml_file(params[:lccn])

    begin
      job = Job.new("import_job", {
                      "import_type" => "marcxml_lcnaf_subjects_and_agents",
                      "jsonmodel_type" => "import_job"
                      },
                    {"lcnaf_import_#{SecureRandom.uuid}" => marcxml_file})

      response = job.upload
      render :json => {'job_uri' => url_for(:controller => :jobs, :action => :show, :id => response['id'])}
    rescue
      render :json => {'error' => $!.to_s}
    end
  end


  private

  def do_search(params)
    searcher.search(params[:family_name], params[:page].to_i, params[:records_per_page].to_i)
  end


  def searcher
    case params[:lcnaf_service]
    when  'lcnaf'
      OpenSearcher.new('http://id.loc.gov/search/', 'http://id.loc.gov/authorities/names')
    when 'lcsh'
      OpenSearcher.new('http://id.loc.gov/search/', 'http://id.loc.gov/authorities/subjects')
    end
  end
end
