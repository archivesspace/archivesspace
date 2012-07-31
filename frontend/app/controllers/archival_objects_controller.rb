class ArchivalObjectsController < ApplicationController

  def index
    #@resource = ArchivalObject.all(session[:repo])
  end

  def show
    #@resource = ArchivalObject.find(session[:repo],params[:id_0],params[:id_1],params[:id_2],params[:id_3])
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

end
