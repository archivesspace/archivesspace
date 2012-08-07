class ArchivalObjectsController < ApplicationController

  def index
     @archival_objects = JSONModel(:archival_object).all
  end

  def show
     @archival_object = JSONModel(:archival_object).find(params[:id])
     @collection_id = params[:collection_id] if params.has_key?(:collection_id)
     
     if params[:inline]
        return render :partial=>"archival_objects/show_inline"
     end
  end

  def new
     @isFresh = true
     
     @archival_object = JSONModel(:archival_object).new
     @archival_object.title = "New Archival Object"
     @archival_object.parent = JSONModel(:archival_object).uri_for(params[:parent]) if params.has_key?(:parent)
     @archival_object.collection = JSONModel(:collection).uri_for(params[:collection]) if params.has_key?(:collection)
     
     render :partial=>"archival_objects/new_inline"
  end

  def edit
     @archival_object = JSONModel(:archival_object).find(params[:id])
     @isFresh = true
     return render :partial=>"archival_objects/edit_inline" 
  end

  def create
     begin
       @archival_object = JSONModel(:archival_object).new(params[:archival_object])

       if not params.has_key?(:ignorewarnings) and not @archival_object._exceptions.empty?
          return render :partial=>"new_inline"
       end

       id = @archival_object.save
       
       @isFresh = true
       
       render :partial=>"archival_objects/edit_inline"
     rescue JSONModel::ValidationException => e
       @archival_object = e.invalid_object
       render :partial=>"archival_objects/new_inline"
     end
  end
  
  def update
    @archival_object = JSONModel(:archival_object).find(params[:id])
    begin
      @archival_object.replace(params['archival_object'])
      
      if not params.has_key?(:ignorewarnings) and not @archival_object._exceptions.empty?
         return render :partial=>"edit_inline"
      end

      result = @archival_object.save
      
      @isFresh = true
      
      flash[:success] = "Archival Object Saved"
      render :partial=>"edit_inline"
    rescue JSONModel::ValidationException => e
      @archival_object = e.invalid_object
      render :partial=>"edit_inline"
    end
  end
  
  
  private
  
  def find_node(children, id)
     children.each do |child|
        return child if child['id'] === id
        result = find_node(child['children'], id)
        return result if result.kind_of? Hash
     end
  end

  def find_parent_node(tree, id)
     tree['children'].each do |child|
        return tree['id'] if child['id'].to_s === id.to_s
        
        result = find_parent_node(child, id)
        return result if not result.blank?
     end
     nil
  end

end
