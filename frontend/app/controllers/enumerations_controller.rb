class EnumerationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:new, :create, :index, :delete, :destroy, :merge, :set_default]
  before_filter(:only => [:new, :create, :index, :delete, :destroy, :merge, :set_default]) {|c| user_must_have("manage_repository")}

  def new
    @enumeration = JSONModel(:enumeration).find(params[:id])
    render :partial => "new"
  end


  def index
    @enumerations = JSONModel(:enumeration).all.select{|enum| enum['editable']}
    @enumeration = JSONModel(:enumeration).find(params[:id]) if params[:id] and not params[:id].blank?
  end


  def delete
    @merge = !params["merge"].blank?
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params[:value]

    if @merge
      render :partial => "merge"
    else
      render :partial => "delete"
    end
  end
  
  def set_default
    @enumeration = JSONModel(:enumeration).find(params[:id])

    begin
      @enumeration['default_value'] = params[:value]
      @enumeration.save      
      flash[:success] = I18n.t("enumeration._html.messages.default_set")
    rescue
      flash.now[:error] = I18n.t("enumeration._html.messages.default_set_error")
    end
    
    redirect_to(:controller => :enumerations, :action => :index, :id => params[:id])

  end  


  def destroy
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]

    begin
      @enumeration.values -= [@value]
      @enumeration.save

      flash[:success] = I18n.t("enumeration._html.messages.deleted")
      render :text => "Success"
    rescue ConflictException
      flash.now[:error] = I18n.t("enumeration._html.messages.delete_conflict")
      flash.now[:info] = I18n.t("enumeration._html.messages.merge_tip")

      render :partial => "merge"
    rescue
      flash.now[:error] = I18n.t("enumeration._html.messages.delete_error")
      render :partial => "delete"
    end
  end


  def merge
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]
    @merge = params["merge_into"]

    if @merge.blank?
      flash.now[:error] = "#{I18n.t("enumeration.merge_into")} - is required"
      return render :partial => "merge"
    elsif @value.blank?
      flash.now[:error] = "#{I18n.t("enumeration.value")} - is required"
      return render :partial => "merge"
    end

    begin
      request = JSONModel(:enumeration_migration).from_hash(:enum_uri => @enumeration.uri,
                                                            :from => @value,
                                                            :to => @merge)
      request.save

      flash[:success] = I18n.t("enumeration._html.messages.merged")
      render :text => "Success"
    rescue
      flash.now[:error] = I18n.t("enumeration._html.messages.merge_error")
      render :partial => "merge"
    end
  end

  def create
    @enumeration = JSONModel(:enumeration).find(params[:id])

    if params[:enumeration].blank? or params[:enumeration][:value].blank?
      flash.now[:error] = "#{I18n.t("enumeration.value")} is required"
      return render :partial => "new"
    end

    begin
      @enumeration.values += [params[:enumeration][:value]]
      @enumeration.save

      flash[:success] = I18n.t("enumeration._html.messages.created")
      render :text => "Success"
    rescue
      flash.now[:error] = I18n.t("enumeration._html.messages.create_error")
      render :partial => "new"
    end

  end


end
