require 'advanced_query_builder'

class SearchController < ApplicationController

  DETAIL_TYPES = ['accession', 'resource', 'archival_object', 'digital_object',
                  'digital_object_component', 'classification',
                  'agent_person', 'agent_family', 'agent_software', 'agent_corporate_entity']

  VIEWABLE_TYPES = ['agent', 'repository', 'subject'] + DETAIL_TYPES

  FACETS = ["repository", "primary_type", "subjects", "source", "linked_agent_roles"]


  def search
    set_search_criteria

    @search_data = Search.all(@criteria, @repositories)
    @term_map = params[:term_map] ? ASUtils.json_parse(params[:term_map]) : {}

    respond_to do |format|
      format.html { render "search/results" }
      format.js { render_aspace_partial :partial => "search/inline_results", :content_type => "text/html", :locals => {:search_data => @search_data} }
    end
  end

  def advanced_search
    set_advanced_search_criteria

    @search_data = Search.all(@criteria, @repositories)

    render "search/results"
  end

  def repository
    set_search_criteria

    if params[:repo_id].blank?
      @search_data = Search.all(@criteria.merge({"facet[]" => [], "type[]" => ["repository"]}), {})

      return render "search/results"
    end

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @search_data = Search.repo(@repository.id, @criteria, @repositories)

    render "search/results"
  end


  private

  def set_search_criteria
    
    @criteria = params.select{|k,v|
      ["page", "q", "type", "sort",
       "filter_term", "root_record", "format"].include?(k) and not v.blank?
    }
    
    @criteria["page"] ||= 1
    @criteria["sort"] = "title_sort asc" unless @criteria["sort"] or @criteria["q"] or params["advanced"].present?

    if @criteria["filter_term"]
      @criteria["filter_term[]"] = Array(@criteria["filter_term"]).reject{|v| v.blank?}.map { |ft|  ActionController::Base.helpers.sanitize(ft) }
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
  end


  def set_advanced_search_criteria
    set_search_criteria

    terms = (0..2).collect{|i|
      term = search_term(i)

      if term and term["op"] === "NOT"
        term["op"] = "AND"
        term["negated"] = true
      end

      term
    }.compact

    if not terms.empty?
      @criteria["aq"] = AdvancedQueryBuilder.build_query_from_form(terms).to_json
      @criteria['facet[]'] = FACETS
    end
  end

  def search_term(i)
    if not params["v#{i}"].blank?
      { "field" => params["f#{i}"], "value" => params["v#{i}"], "op" => params["op#{i}"], "type" => "text" }
    end
  end

end
