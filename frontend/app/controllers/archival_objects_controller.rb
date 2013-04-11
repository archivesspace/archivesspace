class ArchivalObjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :parent, :transfer]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :parent, :transfer]) {|c| user_must_have("update_archival_record")}

  FIND_OPTS = {
    "resolve[]" => ["subjects", "location", "linked_agents", "digital_object"]
  }

  def new
    @archival_object = JSONModel(:archival_object).new._always_valid!
    @archival_object.title = I18n.t("archival_object.title_default")
    @archival_object.parent = {'ref' => JSONModel(:archival_object).uri_for(params[:archival_object_id])} if params.has_key?(:archival_object_id)
    @archival_object.resource = {'ref' => JSONModel(:resource).uri_for(params[:resource_id])} if params.has_key?(:resource_id)

    return render :partial => "archival_objects/new_inline" if inline?

    # render the full AO form

  end

  def edit
    @archival_object = JSONModel(:archival_object).find(params[:id], FIND_OPTS)
    render :partial => "archival_objects/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :archival_object,
                :find_opts => FIND_OPTS,
                :on_invalid => ->(){ render :partial => "new_inline" },
                :on_valid => ->(id){
                  if params.has_key?(:plus_one)
                    flash[:success] = I18n.t("archival_object._html.messages.created")
                    return render :partial => "archival_objects/edit_inline"
                  end
                  flash.now[:success] = I18n.t("archival_object._html.messages.created")
                  render :partial => "archival_objects/edit_inline"
                })
  end


  def update
    handle_crud(:instance => :archival_object,
                :obj => JSONModel(:archival_object).find(params[:id], FIND_OPTS),
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  flash.now[:success] = I18n.t("archival_object._html.messages.updated")
                  render :partial => "edit_inline"
                })
  end


  def show
    @resource_id = params['resource_id']
    @archival_object = JSONModel(:archival_object).find(params[:id], FIND_OPTS)
    render :partial => "archival_objects/show_inline" if inline?
  end


  def parent
    params[:archival_object] ||= {}
    if params[:parent] and not params[:parent].blank?
      # set parent as AO uri on params
      params[:archival_object][:parent] = {'ref' => JSONModel(:archival_object).uri_for(params[:parent])}
    else
      #remove parent from AO
      params[:archival_object][:parent] = nil
    end

    params[:archival_object][:position] = params[:index].to_i if params.has_key? :index

    handle_crud(:instance => :archival_object,
                :obj => JSONModel(:archival_object).find(params[:id]),
                :replace => false,
                :on_invalid => ->(){
                  raise "Error setting parent of archival object"
                },
                :on_valid => ->(id){ return render :text => "success"})
  end


  def transfer
    begin
      post_data = {
        :target_resource => params["transfer"]["ref"],
        :component => JSONModel(:archival_object).uri_for(params[:id])
      }

      response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/component_transfers", post_data)

      if response.code == '200'
        flash[:success] = I18n.t("archival_object._html.messages.transfer_success")
        redirect_to :controller => :resources, :action => :edit, :id => JSONModel(:resource).id_for(params["transfer"]["ref"]), :anchor => "tree::archival_object_#{params[:id]}"
      else
        raise ASUtils.json_parse(response.body)['error'].to_s     
      end

    rescue Exception => e
      flash[:error] = I18n.t("archival_object._html.messages.transfer_error", :e => e).html_safe
      redirect_to :controller => :resources, :action => :edit, :id => params["transfer"]["current_resource_id"], :anchor => "tree::archival_object_#{params[:id]}"
    end
  end
end
