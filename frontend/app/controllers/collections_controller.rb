class CollectionsController < ApplicationController

  def index
     @collections = JSONModel(:collection).all
  end

  def show
     @collection = JSONModel(:collection).find(params[:id])
     
      if params[:inline]
       return render :partial=>"collections/show_inline"
      end
     
     # get the hierarchy
     # FIXME: this should be using JSONModel
     uri = URI("#{BACKEND_SERVICE_URL}/repositories/#{session[:repo_id]}/collections/#{params[:id]}/tree")
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
     # FIXME: this should be using JSONModel
     uri = URI("#{BACKEND_SERVICE_URL}/repositories/#{session[:repo_id]}/collections/#{params[:id]}/tree")
     response = Net::HTTP.get(uri)
     @collection_tree = JSON.parse(response)
  end

  def create
     begin
       @collection = JSONModel(:collection).new(params[:collection])
       id = @collection.save
       redirect_to :controller=>:collections, :action=>:show, :id=>id
     rescue JSONModel::ValidationException => e
       @collection = e.invalid_object
       @errors = e.errors
       return render action: "new"
     end
  end

  def update
     @collection = JSONModel(:collection).find(params[:id])
     begin
       @collection.update(params['collection'])
       result = @collection.save
       if params["inline"]
         flash[:success] = "Collection Saved"
         render :partial=>"edit_inline"
       else
         redirect_to :controller=>:collection, :action=>:show, :id=>@collection.id
       end
     rescue JSONModel::ValidationException => e
       @collection = e.invalid_object
       @errors = e.errors
       if params["inline"]
         render :partial=>"edit_inline"
       else
         render :action=>"edit", :notice=>"Update failed: #{result[:status]}" 
       end      
     end
  end

  def destroy
     
  end
  
  def add_archival_object
    begin
      @archival_object = JSONModel(:archival_object).new({:title=>"New Archival Object"})

      @archival_object.collection = JSONModel(:collection).uri_for(params[:id])

      if not params[:parent].blank?
        @archival_object.parent = JSONModel(:archival_object).uri_for(params[:parent])
      end

      id = @archival_object.save

      uri = URI("#{BACKEND_SERVICE_URL}/repositories/#{session[:repo_id]}/collections/#{params[:id]}/tree")
      response = Net::HTTP.get(uri)
      @collection_tree = JSON.parse(response)

      result = {
       :id => id,
       :tree => @collection_tree
      }

      render :text=>result.to_json
    rescue JSONModel::ValidationException => e
      render :text=>e.to_json
    end
  end
  
  def tree
    uri = URI("#{BACKEND_SERVICE_URL}/repositories/#{session[:repo_id]}/collections/#{params[:id]}/tree")
    response = Net::HTTP.get(uri)
    render :text=>response
  end
  
end
