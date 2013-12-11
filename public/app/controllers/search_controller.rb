class SearchController < ApplicationController

  DETAIL_TYPES = ['accession', 'resource', 'archival_object', 'digital_object',
                  'digital_object_component', 'classification']

  VIEWABLE_TYPES = ['agent', 'repository', 'subject'] + DETAIL_TYPES


  def search
    set_search_criteria

    @search_data = Search.all(@criteria, @repositories)
    @term_map = params[:term_map] ? ASUtils.json_parse(params[:term_map]) : {}

    respond_to do |format|
      format.html { render "search/results" }
      format.js { render :partial => "search/inline_results", :content_type => "text/html" }
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
    @criteria = params.select{|k,v| ["page", "q", "type", "sort", "filter_term"].include?(k) and not v.blank?}

    @criteria["page"] ||= 1

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
    @criteria['facet[]'] = ["repository", "primary_type", "subjects", "source"]
  end

  def set_advanced_search_criteria
    set_search_criteria

    terms = (0..2).collect{|i|
      term = search_term(i)

      if term and term[:op] === "NOT"
        term[:op] = "AND"
        term[:negated] = true
      end

      term
    }.compact

    if not terms.empty?
      @criteria["aq"] = JSONModel(:advanced_query).from_hash({"query" => group_queries(terms)}).to_json
    end
  end

  def search_term(i)
    if not params["v#{i}"].blank?
      { :field => params["f#{i}"], :value => params["v#{i}"], :op => params["op#{i}"] }
    end
  end

  def group_queries(terms)
    if terms.length > 1
      stack = terms.reverse.clone

      while stack.length > 1
        a = stack.pop
        b = stack.pop

        stack.push(JSONModel(:boolean_query).from_hash({
                                                         :op => b[:op],
                                                         :subqueries => [JSONModel(:field_query).from_hash(a), JSONModel(:field_query).from_hash(b)]
                                                       }))
      end

      stack.pop
    else
      JSONModel(:field_query).from_hash(terms[0])
    end
  end

end
