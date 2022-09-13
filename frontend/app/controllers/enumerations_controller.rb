class EnumerationsController < ApplicationController

  set_access_control "update_enumeration_record" => [:new, :create, :index, :delete, :destroy, :merge, :set_default, :update_value, :csv]


  def new
    @enumeration = JSONModel(:enumeration).find(params[:id])
    render_aspace_partial :partial => "new"
  end


  def index
    # @enumerations = JSONModel(:enumeration).all.select{|enum| enum['editable']}
    @enumerations = JSONModel(:enumeration).all
    @enumeration = JSONModel(:enumeration).find(params[:id]) if params[:id] and not params[:id].blank?
  end


  def current_record
    @enumeration
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
    begin
      @enumeration = JSONModel(:enumeration).find(params[:id])
      @enumeration['default_value'] = params[:value]
      @enumeration.save
      flash[:success] = t("enumeration._frontend.messages.default_set")
    rescue
      flash.now[:error] = t("enumeration._frontend.messages.default_set_error")
    end

    redirect_to(:controller => :enumerations, :action => :index, :id => params[:id])
  end


  # we only update position and suppression here
  def update_value
    @enumeration_value = JSONModel(:enumeration_value).find( params[:enumeration_value_id])

    begin
      if params[:suppressed]
        suppress = ( params[:suppressed] == "1" )
        @enumeration_value.set_suppressed(suppress)
      end

      if params[:position]
        JSONModel::HTTP.post_form("#{@enumeration_value.uri}/position", :position => params[:position])
      end

      flash[:success] = t("enumeration._frontend.messages.value_updated")
    rescue
      flash.now[:error] = t("enumeration._frontend.messages.value_update_error")
    end

    redirect_to(:controller => :enumerations, :action => :index, :id => params[:id])
  end


  def destroy
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]
    @enumeration_value = JSONModel(:enumeration_value).find( params["enumeration"]["enumeration_value_id"])


    begin
      # ANW-1165: Unsuppress value before attempting to delete
      @enumeration_value.set_suppressed(false) if @enumeration_value["suppressed"] == true

      @enumeration.values -= [@value]
      @enumeration.save

      flash[:success] = t("enumeration._frontend.messages.deleted")
      render :plain => "Success"
    rescue ConflictException
      flash.now[:error] = t("enumeration._frontend.messages.delete_conflict")
      flash.now[:info] = t("enumeration._frontend.messages.merge_tip")

      render_aspace_partial :partial => "merge"
    rescue
      flash.now[:error] = t("enumeration._frontend.messages.delete_error")
      render_aspace_partial :partial => "delete"
    end
  end


  def merge
    @enumeration = JSONModel(:enumeration).find(params[:id])
    @value = params["enumeration"]["value"]
    @merge = params["merge_into"]

    if @merge.blank?
      flash.now[:error] = "#{t("enumeration.merge_into")} - is required"
      return render_aspace_partial :partial => "merge"
    elsif @value.blank?
      flash.now[:error] = "#{t("enumeration.value")} - is required"
      return render_aspace_partial :partial => "merge"
    end

    begin
      request = JSONModel(:enumeration_migration).from_hash(:enum_uri => @enumeration.uri,
                                                            :from => @value,
                                                            :to => @merge)
      request.save

      flash[:success] = t("enumeration._frontend.messages.merged")
      render :plain => "Success"
    rescue
      flash.now[:error] = t("enumeration._frontend.messages.merge_error")
      render_aspace_partial :partial => "merge"
    end
  end

  def create
    @enumeration = JSONModel(:enumeration).find(params[:id])

    if params[:enumeration].blank? or params[:enumeration][:value].blank?
      flash.now[:error] = "#{t("enumeration.value")} is required"
      return render_aspace_partial :partial => "new"
    end

    begin
      @enumeration.values += [params[:enumeration][:value]]
      @enumeration.save

      flash[:success] = t("enumeration._frontend.messages.created")
      render :plain => "Success"
    rescue
      flash.now[:error] = t("enumeration._frontend.messages.create_error")
      render_aspace_partial :partial => "new"
    end
  end


  def csv
    @enumerations = JSONModel(:enumeration).all

    self.response.headers['Content-Type'] = 'text/csv'
    self.response.headers['Content-Disposition'] = "attachment; filename=enumerations_#{Time.now.strftime('%Y%m%dT%H%M%S')}.csv"
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/config/enumerations/csv") do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end
end
