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
    @assessment = fetch_resolved(params[:id])

    flash[:info] = I18n.t("assessment._frontend.messages.suppressed_info", JSONModelI18nWrapper.new(:assessment => @assessment)) if @assessment.suppressed
  end


  def new
    @assessment = JSONModel(:assessment).new({:assessment_date => Date.today.strftime('%Y-%m-%d')})._always_valid!
  end


  def edit
    @assessment = JSONModel(:assessment).find(params[:id])

    if @assessment.suppressed
      redirect_to(:controller => :assessments, :action => :show, :id => params[:id])
    end
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
end
