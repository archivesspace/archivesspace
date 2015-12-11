class SearchController < ApplicationController

  DETAIL_TYPES = ['accession', 'resource', 'archival_object', 'digital_object',
                  'digital_object_component', 'classification',
                  'agent_person', 'agent_family', 'agent_software', 'agent_corporate_entity']

  VIEWABLE_TYPES = ['agent', 'repository', 'subject'] + DETAIL_TYPES

  FACETS = ["repository", "primary_type", "subjects", "source", "linked_agent_roles"]



  def search

    set_search_criteria

    @search_data = Search.all(@criteria, @repositories)

    render :json => @search_data
  end


  private

  def set_search_criteria
    @criteria = params.select{|k,v|
      ["page", "page_size", "q", "type", "sort",
       "filter_term", "root_record", "format"].include?(k) and not v.blank?
    }

    @criteria["page"] ||= 1
    @criteria["sort"] = "title_sort asc" unless @criteria["sort"] or @criteria["q"] or params["advanced"].present?

    if @criteria["filter_term"]
      @criteria["filter_term[]"] = Array(@criteria["filter_term"]).reject{|v| v.blank?}
      @criteria.delete("filter_term")
    end

    if params[:type].blank?
      @criteria['type[]'] = DETAIL_TYPES
    else
      @criteria['type[]'] = Array(params[:type]).keep_if {|t| VIEWABLE_TYPES.include?(t)}
      @criteria.delete("type")
    end

    @criteria['exclude[]'] = params[:exclude] if not params[:exclude].blank?
    @criteria['facet[]'] = FACETS

    @criteria['hl'] = true
  end

end
