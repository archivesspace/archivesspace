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

      save_params = {
         :repo_id => session[:repo]
      }
    
      save_params[:collection] = params[:id]
      save_params[:parent] = params[:parent] if not params[:parent].blank?

      id = @archival_object.save(save_params)
         
      uri = URI("#{BACKEND_SERVICE_URL}/collection/#{params[:id]}/tree")
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
    uri = URI("#{BACKEND_SERVICE_URL}/collection/#{params[:id]}/tree")
    response = Net::HTTP.get(uri)
    render :text=>response
  end
  
end
