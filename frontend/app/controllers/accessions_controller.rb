class AccessionsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_accession_record" => [:new, :edit, :create, :update],
                      "transfer_archival_record" => [:transfer],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "delete_archival_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]

  include ExportHelper


  def index
    respond_to do |format| 
      format.html {   
        @search_data = Search.for_type(session[:repo_id], "accession", params_for_backend_search.merge({"facet[]" => SearchResultData.ACCESSION_FACETS}))
      }
      format.csv { 
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.ACCESSION_FACETS})
        search_params["type[]"] = "accession" 
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }  
    end 
  end


  def show
    @accession = fetch_resolved(params[:id])

    flash[:info] = I18n.t("accession._frontend.messages.suppressed_info", JSONModelI18nWrapper.new(:accession => @accession)) if @accession.suppressed
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})._always_valid!

    if params[:accession_id]
      acc = Accession.find(params[:accession_id], find_opts)

      if acc
        @accession.populate_from_accession(acc)
        flash.now[:info] = I18n.t("accession._frontend.messages.spawned", JSONModelI18nWrapper.new(:accession => acc))
        flash[:spawned_from_accession] = acc.id
      end

    elsif user_prefs['default_values']
      defaults = DefaultValues.get 'accession'

      if defaults
        @accession.update(defaults.values)
      end
    end

  end



  def defaults
    defaults = DefaultValues.get 'accession'

    values = defaults ? defaults.form_values : {:accession_date => Date.today.strftime('%Y-%m-%d')}

    @accession = Accession.new(values)._always_valid!

    render "defaults"
  end


  def update_defaults

    begin
      DefaultValues.from_hash({
                                "record_type" => "accession",
                                "lock_version" => params[:accession].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:accession],
                                                                        JSONModel(:accession).schema
                                                                        )
                              }).save

      flash[:success] = I18n.t("default_values.messages.defaults_updated")

      redirect_to :controller => :accessions, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :accessions, :action => :defaults
    end

  end

  def edit
    @accession = fetch_resolved(params[:id])

    if @accession.suppressed
      redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
    end
  end

  def transfer
    begin
      handle_transfer(Accession)
    rescue ArchivesSpace::TransferConflictException => e
      @transfer_errors = e.errors
      show
      render :action => :show
    end
  end


  def create
    handle_crud(:instance => :accession,
                :model => Accession,
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){
                    flash[:success] = I18n.t("accession._frontend.messages.created", JSONModelI18nWrapper.new(:accession => @accession))
                    redirect_to(:controller => :accessions,
                                :action => :edit,
                                :id => id) })
  end

  def update
    handle_crud(:instance => :accession,
                :model => Accession,
                :obj => fetch_resolved(params[:id]),
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("accession._frontend.messages.updated", JSONModelI18nWrapper.new(:accession => @accession))
                  redirect_to :controller => :accessions, :action => :edit, :id => id
                })
  end

  def suppress
    accession = Accession.find(params[:id])
    accession.set_suppressed(true)

    flash[:success] = I18n.t("accession._frontend.messages.suppressed", JSONModelI18nWrapper.new(:accession => accession))
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  def unsuppress
    accession = Accession.find(params[:id])
    accession.set_suppressed(false)

    flash[:success] = I18n.t("accession._frontend.messages.unsuppressed", JSONModelI18nWrapper.new(:accession => accession))
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  def delete
    accession = Accession.find(params[:id])
    begin
      accession.delete
    rescue ConflictException => e
      flash[:error] = I18n.t("accession._frontend.messages.delete_conflict", :error => I18n.t("errors.#{e.conflicts}", :default => e.message))
      return redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
    end

    flash[:success] = I18n.t("accession._frontend.messages.deleted", JSONModelI18nWrapper.new(:accession => accession))
    redirect_to(:controller => :accessions, :action => :index, :deleted_uri => accession.uri)
  end


  private

  # refactoring note: suspiciously similar to resources_controller.rb
  def fetch_resolved(id)
    accession = Accession.find(id, find_opts)

    if accession['classifications']
      accession['classifications'].each do |classification|
        next unless classification['_resolved']
        resolved = classification["_resolved"]
        resolved['title'] = ClassificationHelper.format_classification(resolved['path_from_root'])
      end
    end

    accession
  end


end
