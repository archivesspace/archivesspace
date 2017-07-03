class AssessmentsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_assessment_record" => [:new, :edit, :create, :update],
                      "delete_archival_record" => [:delete]

  def index
    respond_to do |format| 
      format.html {   
        @search_data = Search.for_type(session[:repo_id], "assessment", params_for_backend_search.merge({"facet[]" => SearchResultData.ASSESSMENT_FACETS}))
      }
      format.csv { 
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.ASSESSMENT_FACETS})
        search_params["type[]"] = "assessment" 
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }  
    end 
  end


  def show
    @assessment = JSONModel(:assessment).find(params[:id], 'resolve[]' => ['surveyed_by', 'records'])
  end


  def new
    @assessment = JSONModel(:assessment).new({:assessment_date => Date.today.strftime('%Y-%m-%d')})._always_valid!
  end


  def edit
    @assessment = JSONModel(:assessment).find(params[:id], 'resolve[]' => ['surveyed_by', 'records'])
  end


  def create
    handle_crud(:instance => :assessment,
                :model => JSONModel(:assessment),
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){
                    flash[:success] = I18n.t("assessment._frontend.messages.created", JSONModelI18nWrapper.new(:assessment => @assessment))
                    redirect_to(:controller => :assessments,
                                :action => :edit,
                                :id => id) })
  end


  def update
    handle_crud(:instance => :assessment,
                :model => JSONModel(:assessment),
                :obj => fetch_resolved(params[:id]),
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("assessment._frontend.messages.updated", JSONModelI18nWrapper.new(:assessment => @assessment))
                  redirect_to :controller => :assessments, :action => :edit, :id => id
                })
  end


  def delete
    assessment = JSONModel(:assessment).find(params[:id])
    assessment.delete

    flash[:success] = I18n.t("assessment._frontend.messages.deleted", JSONModelI18nWrapper.new(:assessment => assessment))
    redirect_to(:controller => :assessments, :action => :index, :deleted_uri => assessment.uri)
  end


  private

  def cleanup_params_for_schema(params_hash, schema)
    if ASUtils.wrap(params_hash.dig('records', 'ref')).length > 0
      params_hash['records'] = ASUtils.wrap(params_hash['records']['ref']).zip(ASUtils.wrap(params_hash['records']['_resolved'])).map {|ref, resolved|
        {
          'ref' => ref,
          '_resolved' => resolved
        }
      }
    end

    if ASUtils.wrap(params_hash.dig('surveyed_by', 'ref')).length > 0
      params_hash['surveyed_by'] = ASUtils.wrap(params_hash['surveyed_by']['ref']).zip(ASUtils.wrap(params_hash['surveyed_by']['_resolved'])).map {|ref, resolved|
        {
          'ref' => ref,
          '_resolved' => resolved
        }
      }
    end

    super
  end
end
