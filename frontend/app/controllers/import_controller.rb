class ImportController < ApplicationController

  skip_before_filter :unauthorised_access

  def index
    
    unless session[:repo_id] and session[:repo_id] > 1
      flash[:notice] = "You need to select a repository before importing"
    end
    @importer_list = ASpaceImport::Importer.list

  end
  
  def upload

    if params[:upload].blank?
      flash[:error] = "Please select an EAD file to upload"
    else
      source_file = ImportFile.new(params[:upload])

      # invoke a new importer and pass the file to it
      # return the results of the import to the screen
      # delete the uploaded file

      begin

        results = run_import(source_file)

        source_file.delete

        flash[:success] = results

      rescue ValidationException => e
        errors_str = e.errors.collect.map{|attr, err| "#{e.invalid_object.class.record_type}/#{attr} #{err.join(', ')}"}.join("")
        flash[:error] = "Error importing file: <br/> <div class='offset1'>#{errors_str}</div>".html_safe
      rescue Exception => e
        flash[:error] = "Error importing file: <br/> <div class='offset1'>#{e.class.name} #{e.inspect}</div>".html_safe
      end

    end

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

