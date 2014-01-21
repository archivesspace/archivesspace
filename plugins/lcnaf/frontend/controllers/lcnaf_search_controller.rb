require 'srusearcher'

class LcnafSearchController < ApplicationController

  set_access_control "update_agent_record" => [:search]

  def search
    searcher = SRUSearcher.new('http://alcme.oclc.org/srw/search/lcnaf')
    render :json => searcher.search(SRUQuery.name_search("Giles"), 2, 10).to_json
  end

end
