require 'srusearcher'

class LcnafController < ApplicationController

  set_access_control "update_agent_record" => [:search, :index, :import]

  def index
    @page = 1
    @records_per_page = 10
  end

  def search
    searcher = SRUSearcher.new('http://alcme.oclc.org/srw/search/lcnaf')
    query = SRUQuery.name_search(params[:query])
    render :json => searcher.search(query, params[:page].to_i, params[:records_per_page].to_i).to_json
  end

  def import
    render :json => params.to_json
  end
end
