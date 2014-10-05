class AccessionsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_accession_record" => [:new, :edit, :create, :update],
                      "transfer_archival_record" => [:transfer],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "delete_archival_record" => [:delete]

  before_filter :set_event_types,  :only => [:show, :edit, :update]


  def index
    @search_data = Search.for_type(session[:repo_id], "accession", params_for_backend_search.merge({"facet[]" => SearchResultData.ACCESSION_FACETS}))
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
    end
  end


  def edit
    @accession = fetch_resolved(params[:id])

    if @accession.suppressed
      redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
    end
  end

  def transfer
    handle_transfer(Accession)
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
    accession.delete

    flash[:success] = I18n.t("accession._frontend.messages.deleted", JSONModelI18nWrapper.new(:accession => accession))
    redirect_to(:controller => :accessions, :action => :index, :deleted_uri => accession.uri)
  end


  private

  # refactoring note: suspiciously similar to resources_controller.rb
  def fetch_resolved(id)
    accession = Accession.find(id, find_opts)

    if accession['classification'] && accession['classification']['_resolved']
      resolved = accession['classification']['_resolved']
      resolved['title'] = ClassificationHelper.format_classification(resolved['path_from_root'])
    end

    accession
  end

  def set_event_types
    @accession_event_types = ['acknowledgement_sent', 'agreement_sent', 'agreement_signed', 'cataloged', 'copyright_transfer', 'processed']
  end

end
