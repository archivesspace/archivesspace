class EnumerationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:new, :create, :index, :delete, :destroy, :merge]
  before_filter :user_needs_to_be_a_manager, :only => [:new, :create, :index, :delete, :destroy, :merge]

  def new
    @enumeration = JSONModel(:enumeration).find(params[:id])
    render :partial => "new"
  end


  def index
    @enumerations = JSONModel(:enumeration).all
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


  def destroy
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]

    begin
      @enumeration.values -= [@value]
      @enumeration.save

      flash[:success] = "Enumeration Value Deleted"
      render :text => "Success"
    rescue ConflictException
      flash.now[:error] = "Unable to delete Enumeration as it's currently being referenced by a record"
      flash.now[:info] = "This Value may be merged with another."

      render :partial => "merge"
    rescue
      flash.now[:error] = "Failed to delete Enumeration"
      render :partial => "delete"
    end
  end


  def merge
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]
    @merge = params["merge_into"]

    if @merge.blank?
      flash.now[:error] = "Merge Into is required"
      return render :partial => "merge"
    elsif @value.blank?
      flash.now[:error] = "Value is required"
      return render :partial => "merge"
    end

    begin
      request = JSONModel(:enumeration_migration).from_hash(:enum_uri => @enumeration.uri,
                                                            :from => @value,
                                                            :to => @merge)
      request.save

      flash[:success] = "Enumeration Value Merged"
      render :text => "Success"
    rescue
      flash.now[:error] = "Failed to Merge Enumeration"
      render :partial => "merge"
    end
  end

  def create
    @enumeration = JSONModel(:enumeration).find(params[:id])

    if params[:enumeration].blank? or params[:enumeration][:value].blank?
      flash.now[:error] = "Value is required"
      return render :partial => "new"
    end

    begin
      @enumeration.values += [params[:enumeration][:value]]
      @enumeration.save

      flash[:success] = "Enumeration Value Created"
      render :text => "Success"
    rescue
      flash.now[:error] = "Failed to save Enumeration"
      render :partial => "new"
    end

  end


end
