class ClassificationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :delete, :accept_children]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :accept_children]) {|c| user_must_have("update_classification_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_classification_record")}

  FIND_OPTS = {
    "resolve[]" => ["creator"]
  }

  def index
    @search_data = Search.for_type(session[:repo_id], "classification", search_params.merge({"facet[]" => SearchResultData.CLASSIFICATION_FACETS}))
  end

  def show
    @classification = JSONModel(:classification).find(params[:id], FIND_OPTS)

    if params[:inline]
      return render :partial => "classifications/show_inline"
    end
    flash.keep
    fetch_tree
  end

  def new
    @classification = JSONModel(:classification).new(:title => I18n.t("classification.title_default", :default => ""))._always_valid!

    return render :partial => "classifications/new_inline" if params[:inline]
  end


  def edit
    @classification = JSONModel(:classification).find(params[:id], FIND_OPTS)

    fetch_tree
    flash.keep if not flash.empty? # keep the notices so they display on the subsequent ajax call
    return render :partial => "classifications/edit_inline" if params[:inline]
  end


  def create
    flash.keep(:spawned_from_accession)

    handle_crud(:instance => :classification,
                :on_invalid => ->(){
      render action: "new"
    },
      :on_valid => ->(id){
      redirect_to({
                    :controller => :classifications,
                    :action => :edit,
                    :id => id
                  },
                  :flash => {:success => I18n.t("classification._frontend.messages.created", JSONModelI18nWrapper.new(:classification => @classification))})
    })
  end


  def update
    handle_crud(:instance => :classification,
                :obj => JSONModel(:classification).find(params[:id], FIND_OPTS),
                :on_invalid => ->(){
      render :partial => "edit_inline"
    },
      :on_valid => ->(id){
      @refresh_tree_node = true
    flash.now[:success] = I18n.t("classification._frontend.messages.updated", JSONModelI18nWrapper.new(:classification => @classification))
    render :partial => "edit_inline"
    })
  end


  def delete
    classification = JSONModel(:classification).find(params[:id])
    classification.delete

    flash[:success] = I18n.t("classification._frontend.messages.deleted", JSONModelI18nWrapper.new(:classification => classification))
    redirect_to(:controller => :classifications, :action => :index, :deleted_uri => classification.uri)
  end


  def accept_children
    handle_accept_children(JSONModel(:classification))
  end


  private

  def fetch_tree
    @tree = JSONModel(:classification_tree).find(nil, :classification_id => @classification.id)
  end

end
