class CollectionsController < ApplicationController

  def index
     @collections = JSONModel(:collection).all(:repo_id => session[:repo])
  end

  def show
     @collection = JSONModel(:collection).find(params[:id])
     
      if params[:inline]
       return render :partial=>"collections/show_inline"
      end
     
     # get the hierarchy
     uri = URI("#{BACKEND_SERVICE_URL}/collection/#{@collection.id}/tree")
     response = Net::HTTP.get(uri)
     @collection_tree = JSON.parse(response)
  end

  def new
     @collection = JSONModel(:collection).new({:title=>"New Collection"})
     @collection_tree = {}
  end

  def edit
     @collection = JSONModel(:collection).find(params[:id])
     
     if params[:inline]
      return render :partial=>"collections/edit_inline"
     end
     
     # get the hierarchy
     uri = URI("#{BACKEND_SERVICE_URL}/collection/#{@collection.id}/tree")
     response = Net::HTTP.get(uri)
     @collection_tree = JSON.parse(response)
  end

  def create
     begin
       @collection = JSONModel(:collection).new(params[:collection])
       id = @collection.save(:repo_id => session[:repo])
       redirect_to :controller=>:collections, :action=>:show, :id=>id
     rescue JSONModel::ValidationException => e
       @collection = e.invalid_object
       @errors = e.errors
       return render action: "new"
     end
  end

  def update

  end

  def destroy
     
  end
  
end
