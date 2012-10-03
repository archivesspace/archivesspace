class ImportController < ApplicationController
  def index
    
    @importer_list = ASpaceImport::Importer.list

  end
  
  def upload
    source_file = ImportFile.new(params[:upload])

    # invoke a new importer and pass the file to it
    # return the results of the import to the screen
    # delete the uploaded file
    results = run_import(source_file)
    
    render :text => "File has been uploaded and importer with the following results #{results}"
  end
  
  
  protected
  
  def run_import(source_file)
    
    options = {:dry => false, 
               :relaxed => false, 
               :verbose => false, 
               :repo_id => session[:repo_id], 
               :vocab_id => '1',
               :importer => 'xml',
               :crosswalk => 'ead',
               :input_file => source_file.path}
    
    i = ASpaceImport::Importer.create_importer(options)
    i.run
  
  end
  
end

