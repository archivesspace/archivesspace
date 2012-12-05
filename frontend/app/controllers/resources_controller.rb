class ResourcesController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  def index
    @search_data = JSONModel(:resource).all(:page => selected_page)
  end

  def show
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => ["subjects", "location", "ref", "related_accessions"])

    if params[:inline]
      return render :partial => "resources/show_inline"
    end

    fetch_tree
  end

  def new
    @resource = Resource.new(:title => "New Resource")._always_valid!

    if params[:accession_id]
      acc = Accession.find(params[:accession_id],
                           "resolve[]" => ["subjects", "location", "ref"])
      @resource.populate_from_accession(acc) if acc
    end

    return render :partial => "resources/new_inline" if params[:inline]
  end


  def edit
    @resource = JSONModel(:resource).find(params[:id], "resolve[]" => ["subjects", "location", "ref", "related_accessions"])
    fetch_tree
    return render :partial => "resources/edit_inline" if params[:inline]
  end


  def create
    handle_crud(:instance => :resource,
                :on_invalid => ->(){
                  return render :partial => "resources/new_inline" if params[:inline]
                  render action: "new"
                },
                :on_valid => ->(id){
                  flash[:success] = "Resource Created"

                  puts @resource.inspect
                  puts "ID: #{@resource.id}"

                  return render :partial => "resources/edit_inline" if params[:inline]
                  redirect_to(:controller => :resources,
                              :action => :edit,
                              :id => id)
                 })
  end


  def update
    handle_crud(:instance => :resource,
                :obj => JSONModel(:resource).find(params[:id],
                                                  "resolve[]" => ["subjects", "location", "ref", "related_accessions"]),
                :on_invalid => ->(){
                  render :partial => "edit_inline"
                },
                :on_valid => ->(id){
                  flash[:success] = "Resource Saved"
                  render :partial => "edit_inline"
                })
  end


  private

  def fetch_tree
    @tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource.id)
  end

end
