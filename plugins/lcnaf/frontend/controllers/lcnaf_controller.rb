require 'srusearcher'
require 'securerandom'

class LcnafController < ApplicationController

  set_access_control "update_agent_record" => [:search, :index, :import]

  def index
    @page = 1
    @records_per_page = 10
  end


  def search
    query = SRUQuery.name_search(params[:family_name], params[:given_name]  )
    render :json => searcher.search(query, params[:page].to_i, params[:records_per_page].to_i).to_json
  end


  def import
    marcxml_file = searcher.results_to_marcxml_file(SRUQuery.lccn_search(params[:lccn]))

    begin
      job = Job.new("marcxml_lcnaf_subjects_and_agents",
                    {"lcnaf_import_#{SecureRandom.uuid}" => marcxml_file})

      response = job.upload
      render :json => {'job_uri' => url_for(:controller => :jobs, :action => :show, :id => response['id'])}
    rescue
      render :json => {'error' => $!.to_s}
    end
  end


  private

  def searcher
    SRUSearcher.new('http://alcme.oclc.org/srw/search/lcnaf')
  end

end
