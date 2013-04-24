class AccessionsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :suppress, :unsuppress, :delete]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update]) {|c| user_must_have("update_archival_record")}
  before_filter(:only => [:suppress, :unsuppress]) {|c| user_must_have("suppress_archival_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_archival_record")}

  FIND_OPTS = ["subjects", "related_resources", "linked_agents", "container_locations"]

  def index
    facets = ["subjects", "accession_date_year", "creators"]

    @search_data = Search.for_type(session[:repo_id], "accession", search_params.merge({"facet[]" => facets}))
  end

  def show
    @accession = Accession.find(params[:id], "resolve[]" => FIND_OPTS)

    @accession_event_types = ['acknowledgement_sent', 'agreement_sent', 'agreement_signed', 'copyright_transfer']

    flash[:info] = I18n.t("accession._html.messages.suppressed_info", JSONModelI18nWrapper.new(:accession => @accession)) if @accession.suppressed
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})._always_valid!
  end

  def edit
    @accession = Accession.find(params[:id], "resolve[]" => FIND_OPTS)

    if @accession.suppressed
      redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
    end

    return render :partial => "accessions/edit_inline" if params[:inline]

    fetch_tree
  end

  def create
    handle_crud(:instance => :accession,
                :model => Accession,
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){
                    flash[:success] = I18n.t("accession._html.messages.created", JSONModelI18nWrapper.new(:accession => @accession))
                    redirect_to(:controller => :accessions,
                                                 :action => :show,
                                                 :id => id) })
  end

  def update
    handle_crud(:instance => :accession,
                :model => Accession,
                :obj => JSONModel(:accession).find(params[:id], "resolve[]" => FIND_OPTS),
                :on_invalid => ->(){
                  return render :partial => "accessions/edit_inline" if params[:inline]
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("accession._html.messages.updated", JSONModelI18nWrapper.new(:accession => @accession))
                  return render :partial => "accessions/edit_inline" if params[:inline]
                  redirect_to :controller => :accessions, :action => :show, :id => id
                })
  end

  def suppress
    accession = Accession.find(params[:id])
    accession.set_suppressed(true)

    flash[:success] = I18n.t("accession._html.messages.suppressed", JSONModelI18nWrapper.new(:accession => accession))
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  def unsuppress
    accession = Accession.find(params[:id])
    accession.set_suppressed(false)

    flash[:success] = I18n.t("accession._html.messages.unsuppressed", JSONModelI18nWrapper.new(:accession => accession))
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  def delete
    accession = Accession.find(params[:id])
    accession.delete

    flash[:success] = I18n.t("accession._html.messages.deleted", JSONModelI18nWrapper.new(:accession => accession))
    redirect_to(:controller => :accessions, :action => :index, :deleted_uri => accession.uri)
  end


  private

  def fetch_tree
    @tree = JSONModel(:accession_tree).find(nil, :accession_id => @accession.id)
  end


end
