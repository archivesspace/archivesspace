class EnumerationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:new, :create, :index, :delete, :list, :destroy]
  before_filter :user_needs_to_be_a_manager, :only => [:new, :create, :index, :delete, :list, :destroy]

  def new
    @enumeration = JSONModel::HTTP.get_json("/config/enumerations/#{params[:id]}")
    render :partial => "new"
  end


  def list
    return render :partial => "empty_list" if params[:enum_name].blank?

    @enumeration = JSONModel::HTTP.get_json("/config/enumerations/#{params[:enum_name]}")

    render :partial => "list"
  end


  def index
    @enumerations = JSONModel::HTTP.get_json("/config/enumerations")
    @enumeration = JSONModel::HTTP.get_json("/config/enumerations/#{params[:enum_name]}") if params[:enum_name] and not params[:enum_name].blank?
  end


  def delete
    @merge = !params["merge"].blank?
    @enumeration = JSONModel::HTTP.get_json("/config/enumerations/#{params[:id]}")
    render :partial => "delete"
  end


  def destroy
    @enumeration = JSONModel::HTTP.get_json("/config/enumerations/#{params[:id]}")
    flash[:success] = "Enumeration Value Deleted"
    render :text => "Success"
  end


  def create

    begin
      @enumeration = JSONModel::HTTP.get_json("/config/enumerations/#{params[:id]}")
      flash[:success] = "Enumeration Value Created"
      render :text => "Success"
    rescue
      flash[:error] = "Failed to save Enumeration"
      render :partial => :new
    end

  end


end
