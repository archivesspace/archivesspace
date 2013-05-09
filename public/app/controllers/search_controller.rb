class SearchController < ApplicationController

  def search
    set_search_criteria

    @search_data = Search.all(@criteria, @repositories)

    render "search/results"
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
    @criteria = params.select{|k,v| ["page", "q", "type", "filter", "sort", "filter_term"].include?(k) and not v.blank?}

    @criteria["page"] ||= 1

    if @criteria["type"]
      @criteria["type[]"] = Array(@criteria["type"]).reject{|v| v.blank?}
      @criteria.delete("type")
    end

    if @criteria["filter"]
      @criteria["filter[]"] = Array(@criteria["filter"]).reject{|v| v.blank?}
      @criteria.delete("filter")
    end

    if @criteria["filter_term"]
      @criteria["filter_term[]"] = Array(@criteria["filter_term"]).reject{|v| v.blank?}
      @criteria.delete("filter_term")
    end

    @criteria['type[]'] = Array(params[:type]) if not params[:type].blank?
    @criteria['exclude[]'] = params[:exclude] if not params[:exclude].blank?
    @criteria['facet[]'] = ["repository", "primary_type", "subjects", "source"]

    # only allow locations, subjects, resources and archival objects in search results
    if params["type"].blank? or @criteria['type[]'].empty?
      @criteria['type[]'] = ['resource', 'archival_object', 'digital_object', 'digital_object_component']
    else
      @criteria['type[]'].keep_if {|t| ['agent', 'repository', 'resource', 'archival_object', 'digital_object', 'digital_object_component', 'subject'].include?(t)}
    end

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
