require_relative 'converter'
class EADConverter < Converter

  require 'securerandom'
  require_relative 'lib/xml_sax'
  include ASpaceImport::XML::SAX


  def self.import_types(show_hidden = false)
    [
     {
       :name => "ead_xml",
       :description => "Import EAD records from an XML file"
     }
    ]
  end


  def self.instance_for(type, input_file)
    if type == "ead_xml"
      self.new(input_file)
    else
      nil
    end
  end


  def self.profile
    "Convert EAD To ArchivesSpace JSONModel records"
  end

  # We override this to skip nodes that are often very deep
  # We can safely assume ead, c, and archdesc will have children,
  # which greatly helps the performance. 
  def is_node_empty?(node)
    parent_nodes = %w{ ead e archdesc dsc } + (1..12).collect { |n| "c#{ sprintf('%02d', n)}" }  
    if  parent_nodes.include?( node.local_name ) 
      return false 
    else
      return  node.inner_xml.strip.empty? 
    end
  end
  
  # A lot of nodes need tweaking to format the content. Like, people love their p's but they don't
  # actually want to ever see them. 
  def format_content(content)
  	return content if content.nil?
    content.delete!("\n") # first we remove all linebreaks, since they're probably unintentional  
    content.gsub("<p>","").gsub("</p>","\n\n" ).gsub("<p/>","\n\n")
  		   .gsub("<lb/>", "\n\n").gsub("<lb>","\n\n").gsub("</lb>","")
  	     .strip
  end
  

  # alright, wtf.
  # sometimes notes can have things like  lists jammed in them. we need to break those 
  # out, but keep the narrative order of the notes.
  def insert_into_subnotes(split_tag = 'list')
      subnotes =  ancestor(:note_multipart).subnotes 
      theleftovers = nil 
     
      unless subnotes.nil?
        if subnotes.is_a?(Array)
          sn = subnotes.pop
        else
          sn = subnotes
        end   
        
        if sn["content"]
          # clone the object... 
          theleftovers = sn.dup 
          # rip out the list, and put the left overs back in the content 
          content = sn["content"].gsub("ead:#{split_tag}", split_tag) # just in case..
          sn["content"], trash,  theleftovers["content"] = content.partition(/<#{split_tag}[^>]*>.*?<\/#{split_tag}>/m)
          # what a hack. ripping out the list might leave some dangling <p>s 
          [sn, theleftovers].each do |s|
            next if s["content"].nil?
            s["content"] = Nokogiri::XML::DocumentFragment.parse(s["content"].strip.gsub(/^<\/p[^>]*>/,'')).to_xml(:encoding => 'utf-8') 
          end
        end
        
        # put everything before the list back...
        unless ( sn["content"].nil? or  sn["content"].length < 1 ) 
          set ancestor(:note_multipart), :subnotes, sn 
        end 
     
      end 
        # now return the leftovers to be delt with after the list subnote has
        # been created
        theleftovers
  end




  def self.configure

    with 'ead' do |node|
      make :resource
    end

    ignore "titlepage"

    with 'eadheader' do
      set :finding_aid_status, att('findaidstatus')
    end

    with 'archdesc' do
      set :level, att('level') || 'otherlevel'
      set :other_level, att('otherlevel')
      set :publish, att('audience') == 'external'
    end


    # c, c1, c2, etc...
    (0..12).to_a.map {|i| "c" + (i+100).to_s[1..-1]}.push('c').each do |c|
      with c do
        make :archival_object, {
          :level => att('level') || 'otherlevel',
          :other_level => att('otherlevel'),
          :ref_id => att('id'),
          :resource => ancestor(:resource),
          :parent => ancestor(:archival_object),
          :publish => att('audience') != 'internal'
        }
      end
    end


    with 'unitid' do |node|
      ancestor(:note_multipart, :resource, :archival_object) do |obj|
        case obj.class.record_type
        when 'resource'
          # inner_xml.split(/[\/_\-\.\s]/).each_with_index do |id, i|
          #   set receiver, "id_#{i}".to_sym, id
          # end
          set obj, :id_0, inner_xml
        when 'archival_object'
          set obj, :component_id, inner_xml
        end
      end
    end


    with 'unittitle' do |node|
      ancestor(:note_multipart, :resource, :archival_object) do |obj|
        unless obj.class.record_type == "note_multipart"   
          title = Nokogiri::XML::DocumentFragment.parse(inner_xml.strip)
          title.xpath(".//unitdate").remove 
          obj.title = format_content( title.to_xml(:encoding => 'utf-8') ) 
        end
      end
    end


    with 'unitdate' do |node|

      norm_dates = (att('normal') || "").sub(/^\s/, '').sub(/\s$/, '').split('/')
      #why were the next 3 lines added?  removed for now, since single dates can stand on their own.
      #if norm_dates.length == 1
      #  norm_dates[1] = norm_dates[0]
      #end
      norm_dates.map! {|d| d =~ /^([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)$/ ? d : nil}
      
      make :date, {
        :date_type => att('type') || 'inclusive', 
        :expression => inner_xml,
        :label => 'creation',
        :begin => norm_dates[0],
        :end => norm_dates[1],
        :calendar => att('calendar'),
        :era => att('era'),
        :certainty => att('certainty')
      } do |date|
        set ancestor(:resource, :archival_object), :dates, date
      end
    end


    with "langmaterial" do
      # first, assign the primary language to the ead
      langmaterial = Nokogiri::XML::DocumentFragment.parse(inner_xml)
      langmaterial.children.each do |child|
        if child.name == 'language'
          set ancestor(:resource, :archival_object), :language, child.attr("langcode")
          break
        end
      end

      # write full tag content to a note, subbing out the language tags
      content = inner_xml
      next if content =~ /\A<language langcode=\"[a-z]+\"\/>\Z/

      if content.match(/\A<language langcode=\"[a-z]+\"\s*>([^<]+)<\/language>\Z/)
        content = $1
      end

      make :note_singlepart, {
        :type => "langmaterial",
        :persistent_id => att('id'),
        :publish => att('audience') != 'internal',
        :content => format_content( content.sub(/<head>.*?<\/head>/, '') )
      } do |note|
        set ancestor(:resource, :archival_object), :notes, note
      end
    end


    def make_single_note(note_name, tag, tag_name="")
      content = tag.inner_text
      if !tag_name.empty?
        content = tag_name + ": " + content
      end
      make :note_singlepart, {
        :type => note_name,
        :persistent_id => att('id'),
		    :publish => att('audience') != 'internal',
        :content => format_content( content.sub(/<head>.?<\/head>/, '').strip)
      } do |note|
        set ancestor(:resource, :archival_object), :notes, note
      end
    end
    
    def make_nested_note(note_name, tag)
      content = tag.inner_text
    
      make :note_multipart, {
        :type => note_name,
        :persistent_id => att('id'),
		    :publish => att('audience') != 'internal',
        :subnotes => {
          'jsonmodel_type' => 'note_text',
          'content' => format_content( content )
        }
      } do |note|
        set ancestor(:resource, :archival_object), :notes, note
      end
    end
    
    with 'physdesc' do
      physdesc = Nokogiri::XML::DocumentFragment.parse(inner_xml)
    
      extent_number_and_type = nil
    
      dimensions = []
      physfacets = []
      container_summaries = []
      other_extent_data = []
    
      container_summary_texts = []
      dimensions_texts = []
      physfacet_texts = []
    
      # If there is already a portion of 'part' specified, use it
      if att('altrender') && att('altrender').downcase == 'part'
        portion = 'part'
      else
        portion = 'whole'
      end
    
      physdesc.children.each do |child|
        # "extent" can have one of two kinds of semantic meanings: either a true extent with number and type,
        # or a container summary. Disambiguation is done through a regex.
        if child.name == 'extent'
          child_content = child.content.strip
          if extent_number_and_type.nil? && child_content =~ /^([0-9\.]+)+\s+(.*)$/
            extent_number_and_type = {:number => $1, :extent_type => $2}
          else
            container_summaries << child
            container_summary_texts << child.content.strip
          end
    
        elsif child.name == 'physfacet'
          physfacets << child
          physfacet_texts << child.content.strip
    
        elsif child.name == 'dimensions'
          dimensions << child
          dimensions_texts << child.content.strip
    
        elsif child.name != 'text'
          other_extent_data << child
        end
      end
    
      # only make an extent if we got a number and type, otherwise put all tags in the physdesc in new notes
      if extent_number_and_type
        make :extent, {
          :number => $1,
          :extent_type => $2,
          :portion => portion,
          :container_summary => container_summary_texts.join('; '),
          :physical_details => physfacet_texts.join('; '),
          :dimensions => dimensions_texts.join('; ')
        } do |extent|
          set ancestor(:resource, :archival_object), :extents, extent
        end
    
      # there's no true extent; split up the rest into individual notes
      else
        container_summaries.each do |summary|
          make_single_note("physdesc", summary)
        end
    
        physfacets.each do |physfacet|
          make_single_note("physfacet", physfacet)
        end
        
        dimensions.each do |dimension|
          make_nested_note("dimensions", dimension)
        end
      end
    
      other_extent_data.each do |unknown_tag|
        make_single_note("physdesc", unknown_tag, unknown_tag.name)
      end
    
    end


    with 'bibliography' do
      make :note_bibliography
      set :persistent_id, att('id')
      set ancestor(:resource, :archival_object), :notes, proxy
    end


    with 'index' do
      make :note_index
      set :persistent_id, att('id')
      set ancestor(:resource, :archival_object), :notes, proxy
    end


    %w(bibliography index).each do |x|
      with "#{x}/head" do |node|
        set :label,  format_content( inner_xml )
      end

      with "#{x}/p" do
        set :content, format_content( inner_xml )
      end
    end


    with 'bibliography/bibref' do
      set :items, inner_xml
    end


    {
      'name' => 'name',
      'persname' => 'person',
      'famname' => 'family',
      'corpname' => 'corporate_entity',
      'subject' => 'subject',
      'function' => 'function',
      'occupation' => 'occupation',
      'genreform' => 'genre_form',
      'title' => 'title',
      'geogname' => 'geographic_name'
    }.each do |k, v|
      with "indexentry/#{k}" do |node|
        make :note_index_item, {
          :type => v,
          :value => format_content( inner_xml )
        } do |item|
          set ancestor(:note_index), :items, item
        end
      end
    end

    # this is very imperfect. 
    with 'indexentry/ref' do
        make :note_index_item, {
          :type => 'name',
          :value => inner_xml,
          :reference_text => format_content( inner_xml ),
          :reference =>  att('target')
        } do |item|
          set ancestor(:note_index), :items, item
        end
    end


    %w(accessrestrict accessrestrict/legalstatus \
       accruals acqinfo altformavail appraisal arrangement \
       bioghist custodhist \
       fileplan odd otherfindaid originalsloc phystech \
       prefercite processinfo relatedmaterial scopecontent \
       separatedmaterial userestrict ).each do |note|
      with note do |node|
        content = inner_xml.tap {|xml|
          xml.sub!(/<head>.*?<\/head>/m, '')
          # xml.sub!(/<list [^>]*>.*?<\/list>/m, '')
          # xml.sub!(/<chronlist [^>]*>.*<\/chronlist>/m, '')
        }

        make :note_multipart, {
          :type => node.name,
          :persistent_id => att('id'),
          :publish => att('audience') != 'internal',
          :subnotes => {
            :publish => att('audience') != 'internal',
            'jsonmodel_type' => 'note_text',
            'content' => format_content( content )
          }
        } do |note|
          set ancestor(:resource, :archival_object), :notes, note
        end
      end      
    end


    %w(abstract materialspec physloc).each do |note|
      with note do |node|
        content = inner_xml

        make :note_singlepart, {
          :type => note,
          :persistent_id => att('id'),
          :publish => att('audience') != 'internal',
          :content => format_content( content.sub(/<head>.*?<\/head>/, '') )
        } do |note|
          set ancestor(:resource, :archival_object), :notes, note
        end
      end
    end


    with 'notestmt/note' do
      append :finding_aid_note, format_content( inner_xml )
    end


    with 'chronlist' do
      if  ancestor(:note_multipart)
        left_overs = insert_into_subnotes 
      else 
        left_overs = nil 
        make :note_multipart, {
          :type => node.name,
          :persistent_id => att('id'),
          :publish => att('audience') != 'internal'
        } do |note|
          set ancestor(:resource, :archival_object), :notes, note
        end
      end
      
      make :note_chronology do |note|
        set ancestor(:note_multipart), :subnotes, note
      end
      
      # and finally put the leftovers back in the list of subnotes...
      if ( !left_overs.nil? && left_overs["content"] && left_overs["content"].length > 0 ) 
        set ancestor(:note_multipart), :subnotes, left_overs 
      end 
    end


    with 'chronitem' do
      context_obj.items << {}
    end


    %w(eventgrp/event chronitem/event).each do |path|
      with path do
        context_obj.items.last['events'] ||= []
        context_obj.items.last['events'] << format_content( inner_xml )
      end
    end


    with 'list' do
       
      if  ancestor(:note_multipart)
        left_overs = insert_into_subnotes 
      else 
        left_overs = nil 
        make :note_multipart, {
          :type => 'odd',
          :persistent_id => att('id'),
          :publish => att('audience') != 'internal'
        } do |note|
          set ancestor(:resource, :archival_object), :notes, note
        end
      end
      
      
      # now let's make the subnote list 
      type = att('type')
      if type == 'deflist' || (type.nil? && inner_xml.match(/<deflist>/))
        make :note_definedlist do |note|
          set ancestor(:note_multipart), :subnotes, note
        end
      else
        make :note_orderedlist, {
          :enumeration => att('numeration')
        } do |note|
          set ancestor(:note_multipart), :subnotes, note
        end
      end
      
      
      # and finally put the leftovers back in the list of subnotes...
      if ( !left_overs.nil? && left_overs["content"] && left_overs["content"].length > 0 ) 
        set ancestor(:note_multipart), :subnotes, left_overs 
      end 
    
    end


    with 'list/head' do |node|
      set :title, format_content( inner_xml ) 
    end


    with 'defitem' do |node|
      context_obj.items << {}
    end

    with 'defitem/label' do |node|
      context_obj.items.last['label'] = format_content( inner_xml ) if context == :note_definedlist
    end


    with 'defitem/item' do |node|
      context_obj.items.last['value'] =   format_content( inner_xml ) if context == :note_definedlist
    end


    with 'list/item' do
      set :items, inner_xml if context == :note_orderedlist
    end


    with 'publicationstmt/date' do
      set :finding_aid_date, inner_xml if context == :resource
    end


    with 'date' do
      if context == :note_chronology
        date = inner_xml
        context_obj.items.last['event_date'] = date
      end
    end


    with 'head' do
      if context == :note_multipart
        set :label, format_content( inner_xml ) 
      elsif context == :note_chronology
        set :title, format_content( inner_xml )
      end
    end


    # example of a 1:many tag:record relation (1+ <container> => 1 instance with 1 container)
    with 'container' do
        @containers ||= {}

        # we've found that the container has a parent att and the parent is in
        # our queue
        if att("parent") && @containers[att('parent')]
          cont = @containers[att('parent')]

        else
          # there is not a parent. if there is an id, let's check if there's an
          # instance before we proceed
          inst = context == :instance ? context_obj : context_obj.instances.last 
         
          # if there are no instances, we need to make a new one.
          # or, if there is an @id ( but no @parent) we can assume its a new
          # top level container that will be referenced later, so we need to
          # make a new instance
          if ( inst.nil? or  att('id')  )
            instance_label = att("label") ? att("label") : 'mixed_materials'

            if instance_label =~ /(.*)\s\((.*)\)$/
              instance_label = $1
              barcode = $2
            end

            make :instance, {
              :instance_type => instance_label.downcase.strip
            } do |instance|
              set ancestor(:resource, :archival_object), :instances, instance
            end
            
            inst = context_obj
          end
        
          # now let's check out instance to see if there's a container...
          if inst.container.nil?
            make :container do |cont|
              set inst, :container, cont
            end
          end

          # and now finally we get the container. 
          cont =  inst.container || context_obj
          cont['barcode_1'] = barcode.strip if barcode
          cont['container_profile_key'] = att("altrender")
        end

        # now we fill it in
        (1..3).to_a.each do |i|
          next unless cont["type_#{i}"].nil?
          cont["type_#{i}"] = att('type')
          cont["indicator_#{i}"] = format_content( inner_xml )
          break
        end
        
        #store it here incase we find it has a parent
        @containers[att("id")] = cont if att("id")

    end


    with 'author' do
      set :finding_aid_author, inner_xml
    end


    with 'descrules' do
      set :finding_aid_description_rules, format_content( inner_xml )
    end


    with 'eadid' do
      set :ead_id, inner_xml
      set :ead_location, att('url')
    end


    with 'editionstmt' do
      set :finding_aid_edition_statement, format_content( inner_xml )
    end


    with 'seriesstmt' do
      set :finding_aid_series_statement, format_content( inner_xml )
    end


    with 'sponsor' do
      set :finding_aid_sponsor, format_content( inner_xml )
    end


    with 'titleproper' do
      type = att('type')
      case type
      when 'filing'
        set :finding_aid_filing_title, format_content( inner_xml )
      else
        set :finding_aid_title, format_content( inner_xml )
      end
    end

    with 'subtitle' do
      set :finding_aid_subtitle, format_content( inner_xml )
    end

    with 'langusage' do
      set :finding_aid_language, format_content( inner_xml ) 
    end


    with 'revisiondesc/change' do
      make :revision_statement
      set ancestor(:resource), :revision_statements, proxy
    end

    with 'revisiondesc/change/item' do
      set :description, format_content( inner_xml )
    end
    
    with 'revisiondesc/change/date' do
      set :date, format_content( inner_xml )
    end

    with 'origination/corpname' do
      make_corp_template(:role => 'creator')
    end


    with 'controlaccess/corpname' do
      make_corp_template(:role => 'subject')
    end


    with 'origination/famname' do
      make_family_template(:role => 'creator')
    end


    with 'controlaccess/famname' do
      make_family_template(:role => 'subject')
    end


    with 'origination/persname' do
      make_person_template(:role => 'creator')
    end


    with 'controlaccess/persname' do
      make_person_template(:role => 'subject')
    end


    {
      'function' => 'function',
      'genreform' => 'genre_form',
      'geogname' => 'geographic',
      'occupation' => 'occupation',
      'subject' => 'topical'
      }.each do |tag, type|
        with "controlaccess/#{tag}" do
          make :subject, {
            :terms => {'term' => inner_xml, 'term_type' => type, 'vocabulary' => '/vocabularies/1'},
            :vocabulary => '/vocabularies/1',
            :source => att('source') || 'ingest'
          } do |subject|
            set ancestor(:resource, :archival_object), :subjects, {'ref' => subject.uri}
          end
        end
     end


    with 'dao' do
      make :instance, {
          :instance_type => 'digital_object'
        } do |instance|
          set ancestor(:resource, :archival_object), :instances, instance
      end

      
      make :digital_object, {
        :digital_object_id => SecureRandom.uuid,
        :title => att('title'),
       } do |obj|
         obj.file_versions <<  {   
             :use_statement => att('role'),
             :file_uri => att('href'),
             :xlink_actuate_attribute => att('actuate'),
             :xlink_show_attribute => att('show')
         }
         set ancestor(:instance), :digital_object, obj 
      end

    end
    
    with 'daodesc' do
        make :note_digital_object, {
          :type => 'note',
          :persistent_id => att('id'),
          :content => inner_xml.strip
        } do |note|
          set ancestor(:digital_object), :notes, note
        end
    end
    
    with 'daogrp' do
      title = '' 
      ancestor(:resource, :archival_object ) { |ao| title << ao.title + ' Digital Object' } 
      
      make :digital_object, {
        :digital_object_id => SecureRandom.uuid,
        :title => title,
       } do |obj|
         ancestor(:resource, :archival_object) do |ao|
          ao.instances.push({'instance_type' => 'digital_object', 'digital_object' => {'ref' => obj.uri}})
        end
      end

    end
  
  
   with 'daoloc' do
     ancestor(:digital_object) do |dobj|
      dobj.file_versions << {
       :file_uri => att('href'),
       :xlink_show_attribute => att('show'),
       :file_format_name => att('role')  
       } 
     end
   end
  
  end
 
  
  
  # Templates Section

  def make_corp_template(opts)
    return nil if inner_xml.strip.empty? 
    make :agent_corporate_entity, {
      :agent_type => 'agent_corporate_entity'
    } do |corp|
      set ancestor(:resource, :archival_object), :linked_agents, {'ref' => corp.uri, 'role' => opts[:role]}
    end

    make :name_corporate_entity, {
      :primary_name => inner_xml,
      :rules => att('rules'),
      :authority_id => att('id'), 
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_corporate_entity), :names, proxy
    end
  end


  def make_family_template(opts)
    return nil if inner_xml.strip.empty? 
    make :agent_family, {
      :agent_type => 'agent_family',
    } do |family|
      set ancestor(:resource, :archival_object), :linked_agents, {'ref' => family.uri, 'role' => opts[:role]}
    end

    make :name_family, {
      :family_name => inner_xml,
      :rules => att('rules'),
      :authority_id => att('id'), 
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_family), :names, name
    end
  end


  def make_person_template(opts)
    return nil if inner_xml.strip.empty? 
    make :agent_person, {
      :agent_type => 'agent_person',
    } do |person|
      set ancestor(:resource, :archival_object), :linked_agents, {'ref' => person.uri, 'role' => opts[:role]}
    end

    make :name_person, {
      :name_order => 'inverted',
      :primary_name => inner_xml,
      :authority_id => att('id'), 
      :rules => att('rules'),
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_person), :names, name
    end
  end
end
