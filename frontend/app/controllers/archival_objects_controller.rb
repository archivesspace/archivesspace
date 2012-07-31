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
     if params[:collection_id]
        # get the hierarchy
        uri = URI("#{BACKEND_SERVICE_URL}/collection/#{params[:collection_id]}/tree")
        response = Net::HTTP.get(uri)
        @collection_tree = JSON.parse(response)

        if params[:parent_id] then
           # insert new node below specified parent
           @parent_id = params[:parent_id]
           find_node(@collection_tree['children'], @parent_id.to_i)['children'].push({
             "id" => "new",
             "title" => @archival_object.title,
             "children" => []
           })
        elsif @collection_tree['children'].empty?
           # Add top AO
           @collection_tree['children'].push({
              "id" => "new",
              "title" => @archival_object.title,
              "children" => []              
           })
        else
           # Add child of top AO
           @parent_id = @collection_tree['children'][0]['id']
           @collection_tree['children'][0]['children'].push({
              "id" => "new",
              "title" => @archival_object.title,
              "children" => []
           })
        end
     end
  end

  def edit
     @archival_object = JSONModel(:archival_object).find(params[:id])
     if params[:collection_id]
        # get the hierarchy
        uri = URI("#{BACKEND_SERVICE_URL}/collection/#{params[:collection_id]}/tree")
        response = Net::HTTP.get(uri)
        @collection_tree = JSON.parse(response)        
        @parent_id = find_parent_node(@collection_tree, @archival_object.id.to_s)
     end
  end
  
  def edit_inline
     @archival_object = JSONModel(:archival_object).find(params[:id])
     render action=>"edit_inline", :layout=>nil
  end

  def create
     params[:parent_id] = nil if params[:parent_id].blank?
     params[:collection_id] = nil if params[:collection_id].blank?
          
     begin
       @archival_object = JSONModel(:archival_object).new(params[:archival_object])
       
       save_params = {
          :repo_id => session[:repo]
       }
       save_params[:collection] = params[:collection_id] if not params[:collection_id].blank?
       save_params[:parent] = params[:parent_id] if not params[:parent_id].blank?

       id = @archival_object.save(save_params)
       redirect_to :controller=>:archival_objects, :action=>:show, :id=>id, :collection_id => params["collection_id"]
     rescue JSONModel::ValidationException => e
        if params[:collection_id]
           # get the hierarchy
           uri = URI("#{BACKEND_SERVICE_URL}/collection/#{params[:collection_id]}/tree")
           response = Net::HTTP.get(uri)
           @collection_tree = JSON.parse(response)
           if params[:parent_id] then
              # insert new node below specified parent
           else
              # insert as last child of collection
              @collection_tree['children'].push({
                 "id" => "new",
                 "title" => @archival_object.title,
                 "children" => []              
              })
           end
        end
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
