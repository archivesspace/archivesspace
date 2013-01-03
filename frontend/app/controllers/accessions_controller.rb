class AccessionsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :suppress, :unsuppress]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_manager, :only => [:suppress, :unsuppress]

  FIND_OPTS = ["subjects", "ref", "related_resources", "linked_agents"]

  def index
    @search_data = Accession.all(:page => selected_page)
  end

  def show
    @accession = Accession.find(params[:id], "resolve[]" => FIND_OPTS)
    flash[:info] = "Accession is suppressed and cannot be edited." if @accession.suppressed
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
    munge_related(params[:accession], :related_resources)

    handle_crud(:instance => :accession,
                :model => Accession,
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){
                    flash[:success] = "Accession Created"
                    redirect_to(:controller => :accessions,
                                                 :action => :edit,
                                                 :id => id) })
  end

  def update
    munge_related(params[:accession], :related_resources)

    handle_crud(:instance => :accession,
                :model => Accession,
                :obj => JSONModel(:accession).find(params[:id], "resolve[]" => FIND_OPTS),
                :on_invalid => ->(){
                  return render :partial => "accessions/edit_inline" if params[:inline]
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = "Accession Saved"
                  return render :partial => "accessions/edit_inline" if params[:inline]
                  redirect_to :controller => :accessions, :action => :show, :id => id
                })
  end

  def suppress
    Accession.find(params[:id]).set_suppressed(true)

    flash[:success] = "Accession Suppressed"
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  def unsuppress
    Accession.find(params[:id]).set_suppressed(false)

    flash[:success] = "Accession Unsuppressed"
    redirect_to(:controller => :accessions, :action => :show, :id => params[:id])
  end


  private

  def fetch_tree
    @tree = JSONModel(:accession_tree).find(nil, :accession_id => @accession.id)
  end


end
