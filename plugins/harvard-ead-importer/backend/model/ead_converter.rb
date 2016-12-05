class HarvardEADConverter < EADConverter

  def self.configure
    super

    # fix for <p> problems

    # A lot of nodes need tweaking to format the content. Like, people love their p's but they don't
    # actually want to ever see them.
    def format_content(content)
      return content if content.nil?
      content.tr!("\n", ' ') # literal linebreaks are assumed to not be part of data
      content.gsub(%r{<p(?: [^>/]*)?>},"").gsub(%r{</p>|<p(?:\s+[^>]*)?/>}, "\n\n")
        .gsub("<lb/>", "\n\n").gsub("<lb>","\n\n").gsub("</lb>","")
        .strip
    end


    # Audience fixes
    def make_nested_note(note_name, tag)
      content = tag.encode_special_chars(tag.inner_text)

      make :note_multipart, {
             :type => note_name,
             :persistent_id => att('id'),
		         :publish => att('audience') != 'internal',
             :subnotes => {
               'jsonmodel_type' => 'note_text',
               'content' => format_content( content ),
               'publish' => att('audience') != 'internal' # HAX:DAVE This is wrong, but only used in dimensions handling,
             }
           } do |note|
        set ancestor(:resource, :archival_object), :notes, note
      end
    end

    with 'bibliography' do
      make :note_bibliography
      set :persistent_id, att('id')
      set :publish, att('audience') != 'internal'
      set ancestor(:resource, :archival_object), :notes, proxy
    end

    with 'index' do
      make :note_index
      set :persistent_id, att('id')
      set :publish, att('audience') != 'internal'
      set ancestor(:resource, :archival_object), :notes, proxy
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

      make :note_chronology, {
             :publish => att('audience') != 'internal'
           } do |note|
        set ancestor(:note_multipart), :subnotes, note
      end

      # and finally put the leftovers back in the list of subnotes...
      if ( !left_overs.nil? && left_overs["content"] && left_overs["content"].length > 0 )
        set ancestor(:note_multipart), :subnotes, left_overs
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
        make :note_definedlist, {
          :publish => att('audience') != 'internal'
        } do |note|
          set ancestor(:note_multipart), :subnotes, note
        end
      else
        make :note_orderedlist, {
          :enumeration => att('numeration'),
          :publish => att('audience') != 'internal'
        } do |note|
          set ancestor(:note_multipart), :subnotes, note
        end
      end


      # and finally put the leftovers back in the list of subnotes...
      if ( !left_overs.nil? && left_overs["content"] && left_overs["content"].length > 0 )
        set ancestor(:note_multipart), :subnotes, left_overs
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
             :publish => att('audience') != 'internal',
             :title => att('title')
           } do |obj|
        obj.file_versions <<  {
          :use_statement => att('role'),
          :file_uri => att('href'),
          :xlink_actuate_attribute => att('actuate'),
          :xlink_show_attribute => att('show'),
          :publish => att('audience') != 'internal'
        }
        set ancestor(:instance), :digital_object, obj
      end

    end

    with 'daodesc' do
      make :note_digital_object, {
             :type => 'note',
             :persistent_id => att('id'),
             :publish => att('audience') != 'internal',
             :content => inner_xml.strip
           } do |note|
        set ancestor(:digital_object), :notes, note
      end
    end

    # daogrp fixes
    with 'daogrp' do
      title = att('title')

      unless title
        title = ''
        ancestor(:resource, :archival_object ) { |ao| title << ao.title + ' Digital Object' }
      end

      make :digital_object, {
        :digital_object_id => SecureRandom.uuid,
        :title => title,
        :publish => att('audience') != 'internal'
      } do |obj|
         ancestor(:resource, :archival_object) do |ao|
          ao.instances.push({'instance_type' => 'digital_object', 'digital_object' => {'ref' => obj.uri}})
         end

         # Actuate and Show values applicable to <daoloc>s can come from <arc> elements,
         # so daogrp contents need to be handled together
         dg_contents = Nokogiri::XML::DocumentFragment.parse(inner_xml)

         # Hashify arc attrs keyed by xlink:to
         arc_by_to_val = dg_contents.xpath('arc').map {|arc|
           if arc['xlink:to']
             [arc['xlink:to'], arc]
           else
             nil
           end
         }.reject(&:nil?).reduce({}) {|hsh, (k, v)| hsh[k] = v;hsh}


         dg_contents.xpath('daoloc').each do |daoloc|
           arc = arc_by_to_val[daoloc['xlink:label']] || {}

           fv_attrs = {}

           # attrs on <arc>
           fv_attrs[:xlink_show_attribute] = arc['xlink:show'] if arc['xlink:show']
           fv_attrs[:xlink_actuate_attribute] = arc['xlink:actuate'] if arc['xlink:actuate']

           # attrs on <daoloc>
           fv_attrs[:file_uri] = daoloc['xlink:href'] if daoloc['xlink:href']
           fv_attrs[:use_statement] = daoloc['xlink:role'] if daoloc['xlink:role']
           fv_attrs[:publish] = daoloc['audience'] != 'internal'

           obj.file_versions << fv_attrs
         end
         obj
      end
    end

    with 'daoloc' do
      # nothing! this is here to override super's implementation to prevent duplicate daoloc processing
    end


    # BEGIN INDEX CUSTOMIZATIONS
    # Copied from Bentley HL importer (https://github.com/bentley-historical-library/bhl-ead-importer)

    # The stock EAD converter creates separate index items for each indexentry,
    # one for the value (persname, famname, etc) and one for the reference (ref),
    # even when they are within the same indexentry and are related
    # (i.e., the persname is a correspondent, the ref is a date or a location at which
    # correspondence with that person can be found).
    # The Bentley's <indexentry>s generally look something like:
    # # <indexentry><persname>Some person</persname><ref>Some date or folder</ref></indexentry>
    # # As the <persname> and the <ref> are associated with one another,
    # we want to keep them together in the same index item in ArchiveSpace.

    # This will treat each <indexentry> as one item,
    # creating an index item with a 'value' from the <persname>, <famname>, etc.
    # and a 'reference_text' from the <ref>.

    field_mapping = {
      'name' => 'name',
      'persname' => 'person',
      'famname' => 'family',
      'corpname' => 'corporate_entity',
      'subject' => 'subject',
      'function' => 'function',
      'occupation' => 'occupation',
      'genreform' => 'genre_form',
      'title' => 'title',
      'geogname' => 'geographic_name',
    }

    with 'indexentry' do

      entry_type = ''
      entry_value = ''
      entry_reference = ''
      entry_ref_target = ''

      indexentry = Nokogiri::XML::DocumentFragment.parse(inner_xml)

      indexentry.children.each do |child|

        if field_mapping.key? child.name
          entry_value << child.content
          entry_type << field_mapping[child.name]
        elsif child.name == 'ref' && child.xpath('./ptr').count == 0
          entry_reference << child.content
          entry_ref_target << (child['target'] || '')
        elsif child.name == 'ref'
          entry_reference = format_content( child.inner_html )
        end

      end

      make :note_index_item, {
             :type => entry_type,
             :value => entry_value,
             :reference_text => entry_reference,
             :reference => entry_ref_target
           } do |item|
        set ancestor(:note_index), :items, item
      end
    end

    # Skip the stock importer actions to avoid confusion/duplication
    field_mapping.each do |k, v|
      with "indexentry/#{k}" do |node|
        next
      end
    end

    with 'indexentry/ref' do
      next
    end

    # END INDEX CUSTOMIZATIONS

  end # END configure

end # END class

::EADConverter
::EADConverter = HarvardEADConverter
