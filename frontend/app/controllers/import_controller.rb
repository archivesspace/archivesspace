class ImportController < ApplicationController

  skip_before_filter :unauthorised_access

  def index
    
    @importer_key = params[:importer]
    
    unless session[:repo_id] and session[:repo_id] > 1
      flash.now[:notice] = I18n.t("import.messages.missing_repo")
    end

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

        results = run_import(source_file, params[:importer])

        source_file.delete

        if results[0].match /200/
          flash.now[:success] = results[0]
        else
          flash.now[:error] = I18n.t("import.messages.error_prefix") 
        end
        
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
  
  def run_import(source_file, importer_key)
    
    flags = []
    
    case importer_key
    when 'eac'
      importer = :eac
    when 'ead'
      importer = :ead
    when 'accession_csv'
      importer = :accessions
    when 'digital_object_csv'
      importer = :digital_objects
    when 'marcxml'
      importer = :marcxml
    when 'marcxml_subjects_and_agents'
      importer = :marcxml
      flags << 'subjects_and_agents_only'
    end

        
    options = {:dry => false, 
               :repo_id => session[:repo_id], 
               :vocab_id => '1',
               :importer => importer,
               :importer_flags => flags,
               :quiet => true,
               :input_file => source_file.path}

      i = ASpaceImport::Importer.create_importer(options)    
      i.run_safe
      
      [i.report_summary, i.report]    
  
  end
end

