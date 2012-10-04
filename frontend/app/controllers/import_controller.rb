class ImportController < ApplicationController
  def index
    
    unless session[:repo_id] and session[:repo_id] > 1
      flash[:notice] = "You need to select a repository before importing"
    end
    @importer_list = ASpaceImport::Importer.list

  end
  
  def upload
    
    source_file = ImportFile.new(params[:upload])

    # invoke a new importer and pass the file to it
    # return the results of the import to the screen
    # delete the uploaded file
    
    results = run_import(source_file)
    
    source_file.delete
    
    flash[:notice] = results
    
    redirect_to(:controller => :import,
                :action => :index)
    
  end
  
  
  protected
  
  def run_import(source_file)
    
    options = {:dry => false, 
               :relaxed => false, 
               :verbose => true, 
               :repo_id => session[:repo_id], 
               :vocab_id => '1',
               :importer => 'xml',
               :crosswalk => 'ead',
               :input_file => source_file.path}
    
    i = ASpaceImport::Importer.create_importer(options)
    i.run
    i.report
  
  end
    
  
end

