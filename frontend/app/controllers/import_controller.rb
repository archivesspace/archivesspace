class ImportController < ApplicationController

  skip_before_filter :unauthorised_access

  def index
    
    @importer_key = params[:importer]
    
    unless session[:repo_id] and session[:repo_id] > 1
      flash.now[:notice] = I18n.t("import.messages.missing_repo")
    end

  end
   
   
  def upload_xhr
    # ASpaceImport::Importer.destroy_importers
    # load '../migrations/lib/importer.rb'
    # ASpaceImport::init
    # Rails.logger.debug(params.inspect)
    if params[:upload].blank?
      self.response_body = Enumerator.new do |y|
        y << {'errors' => ["No file uploaded"]}
      end
    else
      
      source_file = ImportFile.new(params[:upload])
      importer = get_importer(source_file, params[:importer])
      self.response_body = Enumerator.new do |y|
        
        finished = false
        while !finished
          begin
            importer.run_safe do |message|

              message.each do |k,v|

                if k == 'finished'
                  v.each do |k,j|
                    cdata = j.is_a?(Array) ? j.join("<br />") : v
                    y << "<div class='import-#{k}'>#{cdata}</div>\n"
                  end
                  v = "Finished"
                end

                cdata = v.is_a?(Array) ? v.join("<br />") : v
                y << "<div data class='import-#{k}'>#{cdata}</div>\n"
                finished = true if k =~ /finished/
              end
            end
          ensure
            finished = true
          end
        end
      end
      
      headers['Last-Modified'] = Time.now.to_s
    end

  end 
  

  # TODO -fix this up for non XHR2 browsers
  def upload

    if params[:upload].blank?
      flash.now[:error] = I18n.t("import.messages.missing_file")
    else
      source_file = ImportFile.new(params[:upload])

      begin

        i = get_importer(source_file, params[:importer])
        
        i.run_safe do |status|
          # send status to the browser
          
          
        end

        # [i.report_summary, i.report]    
        

        source_file.delete

        if results[0].match /200/
          flash.now[:success] = I18n.t("import.messages.complete")
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
  
  def get_importer(source_file, importer_key)
    
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

        
    options = {
               :repo_id => session[:repo_id], 
               :vocab_id => '1',
               :importer => importer,
               :importer_flags => flags,
               :quiet => true,
               :input_file => source_file.path
               }
    ASpaceImport::Importer.create_importer(options)    

  end
end

