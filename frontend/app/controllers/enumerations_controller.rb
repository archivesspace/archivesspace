class EnumerationsController < ApplicationController

  set_access_control  "manage_repository" => [:new, :create, :index, :delete, :destroy, :merge, :set_default]


  def new
    @enumeration = JSONModel(:enumeration).find(params[:id])
    render_aspace_partial :partial => "new"
  end


  def index
    # @enumerations = JSONModel(:enumeration).all.select{|enum| enum['editable']}
    @enumerations = JSONModel(:enumeration).all
    @enumeration = JSONModel(:enumeration).find(params[:id]) if params[:id] and not params[:id].blank?
  end


  def delete
    @merge = !params["merge"].blank?
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params[:value]

    if @merge
      render_aspace_partial :partial => "merge"
    else
      render_aspace_partial :partial => "delete"
    end
  end
  
  def set_default
    @enumeration = JSONModel(:enumeration).find(params[:id])

    begin
      @enumeration['default_value'] = params[:value]
      @enumeration.save      
      flash[:success] = I18n.t("enumeration._frontend.messages.default_set")
    rescue
      flash.now[:error] = I18n.t("enumeration._frontend.messages.default_set_error")
    end
    
    redirect_to(:controller => :enumerations, :action => :index, :id => params[:id])

  end  


  def destroy
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]

    begin
      @enumeration.values -= [@value]
      @enumeration.save

      flash[:success] = I18n.t("enumeration._frontend.messages.deleted")
      render :text => "Success"
    rescue ConflictException
      flash.now[:error] = I18n.t("enumeration._frontend.messages.delete_conflict")
      flash.now[:info] = I18n.t("enumeration._frontend.messages.merge_tip")

      render_aspace_partial :partial => "merge"
    rescue
      flash.now[:error] = I18n.t("enumeration._frontend.messages.delete_error")
      render_aspace_partial :partial => "delete"
    end
  end


  def merge
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]
    @merge = params["merge_into"]

    if @merge.blank?
      flash.now[:error] = "#{I18n.t("enumeration.merge_into")} - is required"
      return render_aspace_partial :partial => "merge"
    elsif @value.blank?
      flash.now[:error] = "#{I18n.t("enumeration.value")} - is required"
      return render_aspace_partial :partial => "merge"
    end

    begin
      request = JSONModel(:enumeration_migration).from_hash(:enum_uri => @enumeration.uri,
                                                            :from => @value,
                                                            :to => @merge)
      request.save

      flash[:success] = I18n.t("enumeration._frontend.messages.merged")
      render :text => "Success"
    rescue
      flash.now[:error] = I18n.t("enumeration._frontend.messages.merge_error")
      render_aspace_partial :partial => "merge"
    end
  end

  def create
    @enumeration = JSONModel(:enumeration).find(params[:id])

    if params[:enumeration].blank? or params[:enumeration][:value].blank?
      flash.now[:error] = "#{I18n.t("enumeration.value")} is required"
      return render_aspace_partial :partial => "new"
    end

    begin
      @enumeration.values += [params[:enumeration][:value]]
      @enumeration.save

      flash[:success] = I18n.t("enumeration._frontend.messages.created")
      render :text => "Success"
    rescue
      flash.now[:error] = I18n.t("enumeration._frontend.messages.create_error")
      render_aspace_partial :partial => "new"
    end

  end


end
