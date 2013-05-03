ASpaceImport::Importer.importer :ead do
  
  require_relative '../lib/xml_sax'
  include ASpaceImport::XML::SAX


  def self.profile
    "Imports EAD To ArchivesSpace"
  end
    
  
  def self.configure
  
    with 'ead' do |node|
      
      open_context :resource
      set_property :level, "collection"
    end
    
    with 'c' do |node|
            
      open_context :archival_object  
      set_property :resource, ancestor(:resource)
      set_property :parent, ancestor(:archival_object)
      set_property :level, node.attributes.find {|a| a[0] == 'level'}[1]
    end
    
    with 'unitid' do |node|      

      receiver = ancestor(:resource, :archival_object)
      case receiver.class.record_type
      when 'resource'
        node.inner_xml.split(/[\/_\-\.\s]/).each_with_index do |id, i|
          set_property receiver, "id_#{i}".to_sym, id
        end
      when 'archival_object'
        set_property receiver, :component_id, node.inner_xml.gsub(/[\/_\-.]/, '_')
      end
    end
                 
    with 'unittitle' do |node|
    
      set_property ancestor(:resource, :archival_object), :title, inner_text
    end
    
    with 'unitdate' do |node|
      
      open_context :date
      
      if (type = node.attributes.find{|a| a[0] == 'type'})
        type = type[1].downcase
        force_end_date = type == 'inclusive' || type == 'bulk' ? true : false
      end
      set_property :expression, node.inner_xml
      set_property :label, 'other'
      if (normal = node.attributes.find{|a| a[0] == 'normal'})
        norm_dates = normal[1].sub(/^\s/, '').sub(/\s$/, '').split('/')
        if norm_dates[0]
          if norm_dates[0] =~ /^([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)$/
            set_property :begin, norm_dates[0]
          else
            @log.warn("Bad patterns for date #{norm_dates[0]}")
          end
        end
        
        if norm_dates[1]
          if norm_dates[1] =~ /^([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)$/
            set_property :end, norm_dates[1]
          else
            @log.warn("Bad patterns for date #{norm_dates[0]}")
          end
        # https://github.com/archivesspace/archivesspace/issues/2  
        elsif force_end_date && norm_dates[0]
          set_property :end, norm_dates[0]
        end
      else
        # https://github.com/archivesspace/archivesspace/issues/2
        # ignore the source type if the source can't provide a begin and an end
        type = nil 
      end
      
      set_property :date_type, type unless type.nil?
      set_property ancestor(:resource, :archival_object), :dates, proxy
    end
      
    with 'language' do |node|
      
      if (langcode = node.attributes.find {|a| a[0] == 'langcode'})
        set_property ancestor(:resource, :archival_object), :language, langcode[1]
      end
    end
    
    with 'extent' do |node|
    
      open_context :extent
      set_property :number, node.inner_xml
      set_property :extent_type, 'reels'
      set_property :portion, 'whole'
      set_property ancestor(:resource, :archival_object), :extents, proxy
    end
    
    with 'subject' do |node|

      open_context :subject
      set_property :source, getat(node, 'source')
      set_property :terms, {'term' => node.inner_xml, 'term_type' => 'Cultural context', 'vocabulary' => '/vocabularies/1'}
      set_property :vocabulary, '/vocabularies/1'
    end
    
    
    with 'bibliography' do |node|
      
      open_context :note_bibliography
      
      set_property :content, node.inner_xml      
      set_property ancestor(:resource, :archival_object), :notes, proxy
    end
    
    with 'index' do |node|
      
      open_context :note_index
      
      set_property :content, node.inner_xml      
      set_property ancestor(:resource, :archival_object), :notes, proxy
    end
    
    %w(accessrestrict accruals acqinfo altformavail appraisal arrangement bioghist custodhist fileplan odd otherfindaid originalsloc phystech prefercite processinfo relatedmaterial scopecontent separatedmaterial userestrict).each do |note|
    
      with note do |node|
      
        open_context :note_multipart
        set_property :type, node.name      
        set_property ancestor(:resource, :archival_object), :notes, proxy
      end
    end
    
    with 'head' do |node|

      if [:note_multipart].include?(context)
        set_property :label, node.inner_xml
      end
    end
    
    %w(p list chronlist legalstatus).each do |note_stuff|
      with note_stuff do |node|

        if [:note_multipart].include?(context)
          set_property :content, node.outer_xml
        end 
      end
    end
    
    with 'persname' do |node|

      open_context :agent_person
      set_property :agent_type, 'agent_person'
      open_context :name_person
      set_property ancestor(:agent_person), :names, proxy
      set_property :source, getat(node, 'source')
      set_property :rules, 'local'
      set_property :name_order, 'direct'
      set_property :primary_name, node.inner_xml
      set_property :sort_name, node.inner_xml      
    end   
    
    with 'container' do |node|
      
      unless context == :container
        open_context :instance 
        set_property :instance_type, 'text'
        open_context :container
      end
      
      container_type = node.attributes.find {|a| a[0] == 'type'}[1].downcase
      indicator = getat(node, 'id')
            
      if context_obj.type_1.nil?
        set_property :type_1, container_type
        set_property :indicator_1, indicator
        set_property :barcode_1, "8675309" # value is required
      elsif context_obj.type_2.nil?
        set_property :type_2, container_type
        set_property :indicator_2, indicator
      elsif context_obj.type_3.nil?
        set_property :type_3, container_type
        set_property :indicator_3, indicator
      else
        @log.warn("Additional container information cannot be applied")
      end
    
    end  
  end  
end

 

