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
        csv_response( uri, Search.build_filters(search_params), "#{t('accession._plural').downcase}." )
      }
    end
  end

  def current_record
    @accession
  end

  def show
    event_hits = fetch_linked_events_count(:accession, params[:id])
    excludes = event_hits > AppConfig[:max_linked_events_to_resolve] ? ['linked_events', 'linked_events::linked_records'] : []
    @accession = fetch_resolved(:accession, params[:id], excludes: excludes)

    @accession['accession_date'] = t('accession.accession_date_unknown') if @accession['accession_date'] == "9999-12-31"

    flash[:info] = t("accession._frontend.messages.suppressed_info") if @accession.suppressed
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})._always_valid!
    defaults = user_defaults('accession')
    @accession.update(defaults.values) if defaults

    if params[:accession_id]
      acc = Accession.find(params[:accession_id], find_opts)

      if acc
        @accession.populate_from_accession(acc)
        flash.now[:info] = t("accession._frontend.messages.spawned", accession_display_string: acc.title)
        flash[:spawned_from_accession] = acc.id
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

      flash[:success] = t("default_values.messages.defaults_updated")

      redirect_to :controller => :accessions, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :accessions, :action => :defaults
    end
  end

  def edit
    @accession = fetch_resolved(:accession, params[:id], excludes: ['linked_events', 'linked_events::linked_records'])
    @accession['accession_date'] = '' if @accession['accession_date'] == "9999-12-31"

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
                :on_invalid => ->() { render action: "new" },
                :on_valid => ->(id) {
                    flash[:success] = t("accession._frontend.messages.created", accession_display_string: @accession.title)
                    if @accession["is_slug_auto"] == false &&
                       @accession["slug"] == nil &&
                       params["accession"] &&
                       params["accession"]["is_slug_auto"] == "1"

                      flash[:warning] = t("slug.autogen_disabled")
                    end
                    redirect_to(:controller => :accessions,
                                :action => :edit,
                                :id => id) })
  end

  def update
    handle_crud(:instance => :accession,
                :model => Accession,
                :obj => fetch_resolved(:accession, params[:id], excludes: ['linked_events', 'linked_events::linked_records']),
                :on_invalid => ->() {
                  return render action: "edit"
                },
                :on_valid => ->(id) {
                  flash[:success] = t("accession._frontend.messages.updated", accession_display_string: @accession.title)
                  if @accession["is_slug_auto"] == false &&
                     @accession["slug"] == nil &&
                     params["accession"] &&
                     params["accession"]["is_slug_auto"] == "1"

                    flash[:warning] = t("slug.autogen_disabled")
                  end

                  redirect_to :controller => :accessions, :action => :edit, :id => id
                })
  end

  def suppress
    accession = Accession.find(params[:id])
    accession.set_suppressed(true)

    flash[:success] = t("accession._frontend.messages.suppressed", accession_display_string: accession.title)
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  def unsuppress
    accession = Accession.find(params[:id])
    accession.set_suppressed(false)

    flash[:success] = t("accession._frontend.messages.unsuppressed", accession_display_string: accession.title)
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  def delete
    accession = Accession.find(params[:id])
    begin
      accession.delete
    rescue ConflictException => e
      flash[:error] = t("accession._frontend.messages.delete_conflict", :error => t("errors.#{e.conflicts}", :default => e.message))
      return redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
    end

    flash[:success] = t("accession._frontend.messages.deleted", accession_display_string: accession.title)
    redirect_to(:controller => :accessions, :action => :index, :deleted_uri => accession.uri)
  end


end
