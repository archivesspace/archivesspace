class ImportController < ApplicationController

  skip_before_filter :unauthorised_access
  skip_before_filter :verify_authenticity_token

  def index
    @importer_key = params[:importer]
        
    unless session[:repo_id] and session[:repo_id] > 1
      flash.now[:notice] = I18n.t("import.messages.missing_repo")
    end

  end
   
   
  def upload_xhr

    if params[:upload].blank?
      self.response_body = Enumerator.new do |y|
        y << {'errors' => ["No file uploaded"]} + "---\n"
      end
    else
      
      repo_id = params[:repo_id] ? params[:repo_id] : session[:repo_id]
      
      source_file = ImportFile.new(params[:upload])
      importer = get_importer(source_file, params[:importer], repo_id)
      self.response_body = Enumerator.new do |y|

        begin
          importer.run_safe do |message|
      
            progress = nil
            
            # message is expected to be a hash
            if message.is_a?(String)
              message = {'string' => message}
            end
            
            if message.has_key?('status') && message['status'].is_a?(String)
              message['status'] = [message['status']]
            end
            
            if message.has_key?('saved')

              message['saved'] = message['saved'].map {|k,v| v[0]}
              # resources/43#tree::archival_object_89591
            end
      
            y << ASUtils.to_json(message) + "---\n"
          end
          
        rescue Exception => e
          Rails.logger.debug("Import Exception #{e.to_s}")
          y << {"errors" => [e.to_s]} + "---\n"
        ensure
        end

      end
      self.response.headers['Last-Modified'] = Time.now.to_s
    end

  end
  
  
  protected
  
  def get_importer(source_file, importer_key, repo_id)
    
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
               :repo_id => repo_id, 
               :vocab_id => '1',
               :importer => importer,
               :importer_flags => flags,
               :quiet => true,
               :input_file => source_file.path,
               :log => Rails.logger
               }
    ASpaceImport::Importer.create_importer(options)    

  end
end

