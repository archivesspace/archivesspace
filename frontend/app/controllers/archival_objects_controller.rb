class ArchivalObjectsController < ApplicationController

  def index
     @archival_objects = JSONModel(:archival_object).all(:repo_id => session[:repo])
  end

  def show
     @archival_object = JSONModel(:archival_object).find(params[:id])
     if params.has_key?(:collection_id) 
        uri = URI("#{BACKEND_SERVICE_URL}/collection/#{params[:collection_id]}/tree")
        response = Net::HTTP.get(uri)
        @collection_tree = JSON.parse(response)
     end
  end

  def new
     @archival_object = JSONModel(:archival_object).new({:title=>"New Archival Object"})
  end

  def edit
     @archival_object = JSONModel(:archival_object).find(params[:id])
     
     # get the hierarchy
     #uri = URI("#{BACKEND_SERVICE_URL}/collection/#{@collection.id}/tree")
     #response = Net::HTTP.get(uri)
     #@collection_tree = JSON.parse(response)
  end
  
  def edit_inline
     @archival_object = JSONModel(:archival_object).find(params[:id])
     render action=>"edit_inline", :layout=>nil
  end

  def create
     begin
       @archival_object = JSONModel(:archival_object).new(params[:archival_object])
       id = @archival_object.save(:repo_id => session[:repo])
       redirect_to :controller=>:archival_object, :action=>:show, :id=>id
     rescue JSONModel::ValidationException => e
       @archival_object = e.invalid_object
       @errors = e.errors
       return render action: "new"
     end
  end
  
  def update
    @archival_object = JSONModel(:archival_object).find(params[:id])
    begin
      @accession.update(params['archival_object'])
      result = @accession.save
      render :text=>"Saved" if params["inline"]
      redirect_to :controller=>:archival_object, :action=>:show, :id=>@accession.id
    rescue JSONModel::ValidationException => e
      @archival_object = e.invalid_object
      @errors = e.errors
      render action: "edit", :notice=>"Update failed: #{result[:status]}"
    end
  end

end
