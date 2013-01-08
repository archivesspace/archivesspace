class ImportController < ApplicationController

  skip_before_filter :unauthorised_access

  def index
    
    unless session[:repo_id] and session[:repo_id] > 1
      flash.now[:notice] = I18n.t("import.messages.missing_repo")
    end
    @importer_list = ASpaceImport::Importer.list

  end
  
  def upload

    if params[:upload].blank?
      flash.now[:error] = I18n.t("import.messages.missing_file")
    else
      source_file = ImportFile.new(params[:upload])

      # invoke a new importer and pass the file to it
      # return the results of the import to the screen
      # delete the uploaded file

      begin

        results = run_import(source_file)

        source_file.delete

        flash.now[:success] = results[0]
        @import_results = results[1]

      rescue ValidationException => e
        errors_str = e.errors.collect.map{|attr, err| "#{e.invalid_object.class.record_type}/#{attr} #{err.join(', ')}"}.join("")
        flash.now[:error] = "#{I18n.t("import.messages.error_prefix")}: <br/> <div class='offset1'>#{errors_str}</div>".html_safe
      rescue Exception => e
        Rails.logger.debug("Exception raised on file import: #{e.inspect}")
        flash.now[:error] = "#{I18n.t("import.messages.error_prefix")}: <br/> <div class='offset1'>#{e.class.name} #{e.inspect}</div>".html_safe
      end

    end

    index
    
    render :index

  end
  
  
  protected
  
  def run_import(source_file)
    
    options = {:dry => false, 
               :relaxed => false, 
               :verbose => false, #verbose report will overflow the cookie 
               :repo_id => session[:repo_id], 
               :vocab_id => '1',
               :importer => 'xml',
               :crosswalk => 'ead',
               :input_file => source_file.path}
    
    i = ASpaceImport::Importer.create_importer(options)    
    i.run
    
    [i.report_summary, i.report]
  
  end
    
  
end

