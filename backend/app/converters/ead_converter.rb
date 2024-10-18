require_relative 'converter'
require 'set'

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

  # A lot of nodes need tweaking to format the content. Like, people love their p's but they don't
  # actually want to ever see them.
  def format_content(content)
    return content if content.nil?
    content.tr!("\n", ' ') # literal linebreaks are assumed to not be part of data
    content.gsub(%r{<p(?: [^>/]*)?>}, "").gsub(%r{</p>|<p(?:\s+[^>]*)?/>}, "\n\n")
      .gsub("<lb/>", "\n\n").gsub("<lb>", "\n\n").gsub("</lb>", "")
      .strip
  end


  # alright, wtf.
  # sometimes notes can have things like  lists jammed in them. we need to break those
  # out, but keep the narrative order of the notes.
  def insert_into_subnotes(split_tag = 'list')
    subnotes = ancestor(:note_multipart).subnotes
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
        sn["content"], trash, theleftovers["content"] = content.partition(/<#{split_tag}[^>]*>.*?<\/#{split_tag}>/m)
        # what a hack. ripping out the list might leave some dangling <p>s
        [sn, theleftovers].each do |s|
          next if s["content"].nil?
          s["content"] = Nokogiri::XML::DocumentFragment.parse(s["content"].strip.gsub(/^<\/p[^>]*>/, '')).to_xml(:encoding => 'utf-8')
        end
      end

      # put everything before the list back...
      unless ( sn["content"].nil? or sn["content"].length < 1 )
        set ancestor(:note_multipart), :subnotes, sn
      end

    end
        # now return the leftovers to be delt with after the list subnote has
        # been created
    theleftovers
  end

  def verify_date_type(date_type)
    date_types = EnumerationValue.filter(
      :enumeration_id => Enumeration.find(:name => 'date_type').values[:id],
      :suppressed => 0,
    ).order(:position).to_a
    .map { |entry| entry.values[:value] }
    .reject { |value| value == 'range' }

    unless date_types.include? date_type
      error_message = "Invalid date type provided: #{date_type}; must be one of: #{date_types}."

      raise EADConverterInvalidDateTypeError, error_message
    end
  end

  def self.configure
    with 'ead' do |*|
      make :resource, {
        :publish => att('audience') != 'internal',
        :finding_aid_language => 'und',
        :finding_aid_script => 'Zyyy'
      }

      @namespace_mappings ||= {}
      @node.attributes.select {|a| a =~ /^xmlns:/}.each do |k, v|
        if v == 'http://www.w3.org/1999/xlink'
          @namespace_mappings[:xlink] = k.sub("xmlns:", "")
        end
      end
    end

    ignore "titlepage"

    # addresses https://archivesspace.atlassian.net/browse/AR-1282
    with 'eadheader' do |*|
      set :finding_aid_status, att('findaidstatus')
    end

    with 'archdesc' do |*|
      publish = if !context_obj.publish || (att('audience') == 'internal')
                  false
                else
                  true
                end
      set :level, att('level') || 'otherlevel'
      set :other_level, att('otherlevel')
      set :publish, publish
    end


    # c, c1, c2, etc...
    (0..12).to_a.map {|i| "c" + (i+100).to_s[1..-1]}.push('c').each do |c|
      with c do |*|
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

      extract_ark = proc do |s|
        if s.start_with?('<extref')
          Nokogiri::XML::DocumentFragment.parse(s)
            .children[0]
            .attribute('xlink:href')
            .value
        elsif s.start_with?('<ref')
          Nokogiri::XML::DocumentFragment.parse(s)
            .children[0]
            .attribute('href')
            .value
        else
          s
        end
      end

      if 'ark' == node.attribute('type') || 'ark' == node.attribute('localtype')
        ancestor(:resource, :archival_object) do |obj|
          set obj, :import_current_ark, extract_ark.call(inner_xml.strip)
        end
      elsif 'ark-superseded' == node.attribute('type') || 'ark-superseded' == node.attribute('localtype')
        ancestor(:resource, :archival_object) do |obj|
          set obj, :import_previous_arks, extract_ark.call(inner_xml.strip)
        end
      else
        ancestor(:note_multipart, :resource, :archival_object) do |obj|
          case obj.class.record_type
          when 'resource'
            # inner_xml.split(/[\/_\-\.\s]/).each_with_index do |id, i|
            #   set receiver, "id_#{i}".to_sym, id
            # end
            set obj, :id_0, inner_xml if obj.id_0.nil? || obj.id_0.empty?
            if node.attribute( "type")
              make :external_id, {
                :source => node.attribute( "type"),
                :external_id => inner_xml
              } do |ext_id|
                set ancestor(:resource ), :external_ids, ext_id
              end
            end
          when 'archival_object'
            set obj, :component_id, inner_xml if obj.component_id.nil? || obj.component_id.empty?
            if node.attribute( "type" )
              make :external_id, {
                :source => node.attribute( "type" ),
                :external_id => inner_xml
              } do |ext_id|
                set ancestor(:resource, :archival_object), :external_ids, ext_id
              end
            end
          end
        end
      end
    end


    with 'unittitle' do |node|
      ancestor(:note_multipart, :resource, :archival_object) do |obj|
        unless obj.class.record_type == "note_multipart"
          title = Nokogiri::XML::DocumentFragment.parse(inner_xml.strip)
          title.xpath(".//unitdate").remove
          obj.title = format_content( title.to_xml(:encoding => 'utf-8') ) if obj.title.nil? || obj.title.empty?
        end
      end
    end


    with 'unitdate' do |node|
      norm_dates = (att('normal') || "").sub(/^\s/, '').sub(/\s$/, '').split('/')
      # why were the next 3 lines added?  removed for now, since single dates can stand on their own.
      #if norm_dates.length == 1
      #  norm_dates[1] = norm_dates[0]
      #end
      norm_dates.map! {|d| d =~ /^([0-9]{4}(\-(1[0-2]|0[1-9])(\-(0[1-9]|[12][0-9]|3[01]))?)?)$/ ? d : nil}

      verify_date_type(att('type')) unless att('type').nil?

      make :date, {
        :date_type => att('type') || ( norm_dates[1] ? 'inclusive' : 'single' ),
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

    with "archdesc/note" do |*|
      make :note_multipart, {
        :type => 'odd',
        :persistent_id => att('id'),
        :publish => att('audience') != 'internal',
        :subnotes => {
          :publish => att('audience') != 'internal',
          'jsonmodel_type' => 'note_text',
          'content' => format_content( inner_xml )
        }
      } do |note|
        set ancestor(:resource, :archival_object), :notes, note
      end
    end


    with 'langmaterial' do |*|
      langmaterial = Nokogiri::XML::DocumentFragment.parse(inner_xml)
      ancestor(:resource, :archival_object) do |obj|
        # if <langmaterial> contains encoded <language> tags create a matching language_and_script record
        if !(languages = langmaterial.xpath('.//language')).empty? && langmaterial.xpath('.//language').any? { |l| l.attr('langcode') }
          languages.each do |language|
            next unless (langcode = language.attr('langcode'))

            script = language.attr('scriptcode')
            make :lang_material, {
              :jsonmodel_type => 'lang_material',
              :language_and_script => {
                'jsonmodel_type' => 'language_and_script',
                'language' => langcode.to_s,
                'script' => script ? script.to_s : nil
              }
            } do |lang|
              set obj, :lang_materials, lang
            end
          end
        # if a resource and no <language> set to undetermined
        elsif obj.class.record_type == 'resource'
          make :lang_material, {
            :jsonmodel_type => 'lang_material',
            :language_and_script => {
              'jsonmodel_type' => 'language_and_script',
              'language' => 'und'
            }
          } do |lang|
            set obj, :lang_materials, lang
          end
        end

        # write full <langmaterial> content to a note, subbing out the language tags (if present)
        langmaterial.search('.//language').each do |node|
          node.replace Nokogiri::XML::Text.new(node.inner_html, node.document)
        end
        content = langmaterial.to_s

        unless content.nil? || content.strip.empty?
          make :lang_material, {
            :jsonmodel_type => 'lang_material',
            :notes => {
              'jsonmodel_type' => 'note_langmaterial',
              'type' => 'langmaterial',
              'persistent_id' => att('id'),
              'publish' => att('audience') != 'internal',
              'content' => [format_content( content.sub(/<head>.*?<\/head>/, '') )]
            }
          } do |note|
            set obj, :lang_materials, note
          end
        end
      end
    end

    # If we've gotten this far and still haven't hit a <langmaterial><language> we must assign an undetermined language value
    with "archdesc/did" do |e|
      if context_obj['jsonmodel_type'] == 'resource' && inner_xml.include?('<langmaterial') == false
        make :lang_material, {
          :jsonmodel_type => 'lang_material',
          :language_and_script => {
            'jsonmodel_type' => 'language_and_script',
            'language' => 'und'
          }
        } do |lang|
          set ancestor(:resource), :lang_materials, lang
          break
        end
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
        :label => att('label'),
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
        :label => att('label'),
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

    with 'physdesc' do |*|
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

      # Special case: if the physdesc is just a plain string with no child elements, treat its contents as a physdesc note
      if physdesc.children.length == 1 && physdesc.children[0].name == 'text'
        container_summaries << physdesc
      else
        # Otherwise, attempt to parse out an extent record from the child elements.
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


    with 'bibliography' do |*|
      make :note_bibliography
      set :persistent_id, att('id')
      set :publish, att('audience') != 'internal'
      set ancestor(:resource, :archival_object), :notes, proxy
    end


    with 'index' do |*|
      make :note_index
      set :persistent_id, att('id')
      set :publish, att('audience') != 'internal'
      set ancestor(:resource, :archival_object), :notes, proxy
    end


    %w(bibliography index).each do |x|
      with "#{x}/head" do |node|
        set :label, format_content( inner_xml )
      end

      with "#{x}/p" do |*|
        set :content, format_content( inner_xml )
      end
    end


    with 'bibliography/bibref' do |*|
      set :items, inner_xml
    end



    # Multiple elements within one indexentry are generally related
    # Parse the indexentry as a fragment, and map the child elements
    # to ASpace equivalents, according to this mapping:

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

    with 'indexentry' do |*|

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


    %w(accessrestrict accessrestrict/legalstatus
       accruals acqinfo altformavail appraisal arrangement
       bioghist custodhist
       fileplan odd otherfindaid originalsloc phystech
       prefercite processinfo relatedmaterial scopecontent
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


    with 'notestmt/note' do |*|
      append :finding_aid_note, format_content( inner_xml )
    end


    with 'chronlist' do |*|
      if ancestor(:note_multipart)
        left_overs = insert_into_subnotes('chronlist')
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


    with 'chronitem' do |*|
      context_obj.items << {}
    end


    %w(eventgrp/event chronitem/event).each do |path|
      with path do |*|
        context_obj.items.last['events'] ||= []
        context_obj.items.last['events'] << format_content( inner_xml )
      end
    end


    with 'list' do |*|

      if ancestor(:note_multipart)
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


    with 'list/item' do |*|
      set :items, inner_xml if context == :note_orderedlist
    end


    with 'publicationstmt/date' do |*|
      set :finding_aid_date, inner_xml if context == :resource
    end


    with 'date' do |*|
      if context == :note_chronology
        date = inner_xml
        context_obj.items.last['event_date'] = date
      end
    end


    with 'head' do |*|
      if context == :note_multipart
        set :label, format_content( inner_xml )
      elsif context == :note_chronology
        set :title, format_content( inner_xml )
      end
    end


    def remember_instance(instance, id = nil)
      @instances ||= {}
      @instances[id] = instance if id
      @last_instance = instance
    end

    def recall_instance(id = nil)
      id ? @instances[id] : @last_instance
    end

    def add_to_instance(type, indicator, id, parent_id = nil)
      if (instance = recall_instance(parent_id))
        sub_container = instance.sub_container
        if sub_container['type_3']
          # trying to add to a full sub_container - this shouldn't happen
        else
          level = sub_container["type_2"].nil? ? "2" : "3"
          sub_container["type_#{level}"] = type
          sub_container["indicator_#{level}"] = indicator

          # remember this one because someone might be adding to it
          remember_instance(instance, id)
        end
      else
        # can't find the instance to add to - this shouldn't happen
      end
    end

    def get_or_make_top_container_uri(type, indicator, barcode, container_profile_name)
      # remember the top_containers we make in this hash
      # the values are top_container uris
      # the keys are barcodes or type:indicator
      # some assumptions:
      #   - barcodes are unique in this repo
      #   - a barcode will never look like a type:indicator
      #   - type:indicator is not unique
      #       but only the last one seen will need to be added to
      #       so it's actually a blessing that prior ones get blatted
      @top_container_uris ||= {}

      if barcode
        if @top_container_uris[barcode]
          return @top_container_uris[barcode]
        elsif (TopContainer.for_barcode(barcode) && TopContainer.for_barcode(barcode).uri)
          return TopContainer.for_barcode(barcode).uri
        end
      elsif @top_container_uris["#{type}:#{indicator}"]
        return @top_container_uris["#{type}:#{indicator}"]
      end

      # don't make a container_profile, but link to one if there's a match
      container_profile = ContainerProfile.filter(:name => container_profile_name).first

      make :top_container, {
        :barcode => barcode,
        :indicator => indicator,
        :type => type
      } do |top_container|
        if container_profile
          set top_container, :container_profile, {:ref => container_profile.uri}
        end
      end

      if barcode
        @top_container_uris[barcode] = context_obj.uri
      else
        @top_container_uris["#{type}:#{indicator}"] = context_obj.uri
      end

      context_obj.uri
    end

    with 'container' do |*|

      if context == :instance
        # this container is nested inside the last one
        # so add to the current sub_container
        # note: there is not an example of this in:
        #     backend/app/exporters/examples/ead/
        # but the previous implementation supported it
        # so continuing support here
        add_to_instance(att('type'), format_content(inner_xml), att('id'))
        return
      end

      if att('parent')
        # this container has a parent attribute
        # so there should have been a sub_container previously
        # with that id that we can add to
        add_to_instance(att('type'), format_content(inner_xml), att('id'), att('parent'))
        return
      end

      if !att('id') && defined?(context_obj.instances) && (instance = context_obj.instances.last)
        # this container doesn't have an @id
        # and has a container sibling before it
        # so even though it doesn't have a parent attribute
        # it is treated as a child of the prior sibling
        # this pattern is seen in the wnyu.xml example
        # it is necessary to test for @id because in vmi.xml a list
        # of sibling containers represents more than one instance
        add_to_instance(att('type'), format_content(inner_xml), att('id'))
        return
      end

      # all of the cases that require adding to an existing sub_container
      # are now handled, so having arrived here it is necessary to
      # create a new instance with a sub_container

      instance_type = att('label') || 'mixed_materials'

      if instance_type =~ /(.*)\s+?[\(\[]\s*(.*?)\s*[\)\]]$/
        instance_type = $1
        barcode = $2
      end

      make :instance, {
        :instance_type => instance_type.downcase.strip
      } do |instance|
        set ancestor(:resource, :archival_object), :instances, instance
      end

      instance = context_obj

      top_container_uri = get_or_make_top_container_uri(att('type'),
                                                    format_content(inner_xml),
                                                    barcode,
                                                    att("altrender"))

      make :sub_container, {
        :top_container => {'ref' => top_container_uri}
      } do |sub_container|
        set instance, :sub_container, sub_container
      end

      # remember the instance as it might be necessary to add to it later
      remember_instance(instance, att('id'))
    end


    with 'author' do |*|
      set :finding_aid_author, inner_xml
    end


    with 'descrules' do |*|
      set :finding_aid_description_rules, format_content( inner_xml )
    end


    with 'eadid' do |*|
      set :ead_id, inner_xml
      set :ead_location, att('url')
    end


    with 'editionstmt' do |*|
      set :finding_aid_edition_statement, format_content( inner_xml )
    end


    with 'seriesstmt' do |*|
      set :finding_aid_series_statement, format_content( inner_xml )
    end


    with 'sponsor' do |*|
      set :finding_aid_sponsor, format_content( inner_xml )
    end


    with 'titleproper' do |*|
      type = att('type')
      case type
      when 'filing'
        set :finding_aid_filing_title, format_content( inner_xml )
      else
        set :finding_aid_title, format_content( inner_xml )
      end
    end

    with 'subtitle' do |*|
      set :finding_aid_subtitle, format_content( inner_xml )
    end

    with 'profiledesc' do |*|
      profiledesc = Nokogiri::XML::DocumentFragment.parse(inner_xml)
      if !(langusage = profiledesc.xpath(".//langusage")).empty?
        # If there is a langcode attribute inside a <language> element, set the finding_aid_language to that langcode and finding_aid_note to full element content
        if (language = langusage.xpath('.//language')).size != 0 && (langcode = langusage.xpath('.//language').attr('langcode'))
          set :finding_aid_language, langcode.to_s
          if (script = language.attr('scriptcode'))
            set :finding_aid_script, script.to_s
          end
        end
        set :finding_aid_language_note, format_content( langusage.inner_text )
      # if no <langusage>, set language to undetermined
      else
        set :finding_aid_language, 'und'
      end
    end

    with 'revisiondesc/change' do |*|
      make :revision_statement
      set ancestor(:resource), :revision_statements, proxy
      set :publish, !(att('audience') === 'internal')
    end

    with 'revisiondesc/change/item' do |*|
      set :description, format_content( inner_xml )
    end

    with 'revisiondesc/change/date' do |*|
      set :date, format_content( inner_xml )
    end

    with 'origination/corpname' do |*|
      make_corp_template(:role => 'creator')
    end


    with 'controlaccess/corpname' do |*|
      make_corp_template(:role => 'subject')
    end


    with 'origination/famname' do |*|
      make_family_template(:role => 'creator')
    end


    with 'controlaccess/famname' do |*|
      make_family_template(:role => 'subject')
    end


    with 'origination/persname' do |*|
      make_person_template(:role => 'creator')
    end


    with 'controlaccess/persname' do |*|
      make_person_template(:role => 'subject')
    end


    {
      'function' => 'function',
      'genreform' => 'genre_form',
      'geogname' => 'geographic',
      'occupation' => 'occupation',
      'subject' => 'topical',
      'title' => 'uniform_title'
      }.each do |tag, type|
       with "controlaccess/#{tag}" do |*|
         make :subject, {
           :terms => {'term' => inner_xml, 'term_type' => type, 'vocabulary' => '/vocabularies/1'},
           :vocabulary => '/vocabularies/1',
           :source => att('source') || 'ingest'
         } do |subject|
           set ancestor(:resource, :archival_object), :subjects, {'ref' => subject.uri}
         end
       end
     end


    with 'dao' do |*|
      make :instance, {
          :instance_type => 'digital_object'
        } do |instance|
        set ancestor(:resource, :archival_object), :instances, instance
      end

      make :digital_object, {
             :digital_object_id => SecureRandom.uuid,
             :publish => att('audience') != 'internal',
             :title => att('title', :xlink)
           } do |obj|
        obj.file_versions << {
          :use_statement => att('role', :xlink),
          :file_uri => att('href', :xlink),
          :xlink_actuate_attribute => att('actuate', :xlink),
          :xlink_show_attribute => att('show', :xlink),
          :publish => att('audience') != 'internal',
        }
        set ancestor(:instance), :digital_object, obj
      end

    end

    with 'daodesc' do |*|
      make :note_digital_object, {
             :type => 'note',
             :persistent_id => att('id'),
             :publish => att('audience') != 'internal',
             :content => inner_xml.strip
           } do |note|
        set ancestor(:digital_object), :notes, note
      end
    end

    with 'daogrp' do |*|
      title = att('title')

      unless title
        title = ''
        ancestor(:resource, :archival_object ) { |ao|
          display_string = ArchivalObject.produce_display_string(ao)
          display_string = Nokogiri::XML::DocumentFragment.parse(display_string).inner_text
          title << display_string + ' Digital Object'
        }
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
        }.reject(&:nil?).reduce({}) {|hsh, (k, v)| hsh[k] = v; hsh}


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
  end



  # Templates Section

  def make_corp_template(opts)
    return nil if inner_xml.strip.empty?
    make :agent_corporate_entity, {
      :agent_type => 'agent_corporate_entity',
      :publish => att('audience') == 'external' ? true : false
    } do |corp|
      set ancestor(:resource, :archival_object), :linked_agents, {'ref' => corp.uri, 'role' => opts[:role], 'relator' => att('role')}
    end

    make :name_corporate_entity, {
      :primary_name => inner_xml,
      :rules => att('rules'),
      :authority_id => att('authfilenumber'),
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_corporate_entity), :names, proxy
    end
  end


  def make_family_template(opts)
    return nil if inner_xml.strip.empty?
    make :agent_family, {
      :agent_type => 'agent_family',
      :publish => att('audience') == 'external' ? true : false
    } do |family|
      set ancestor(:resource, :archival_object), :linked_agents, {'ref' => family.uri, 'role' => opts[:role], 'relator' => att('role')}
    end

    make :name_family, {
      :family_name => inner_xml,
      :rules => att('rules'),
      :authority_id => att('authfilenumber'),
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_family), :names, name
    end
  end


  def make_person_template(opts)
    return nil if inner_xml.strip.empty?
    make :agent_person, {
      :agent_type => 'agent_person',
      :publish => att('audience') == 'external' ? true : false
    } do |person|
      set ancestor(:resource, :archival_object), :linked_agents, {'ref' => person.uri, 'role' => opts[:role], 'relator' => att('role')}
    end

    make :name_person, {
      :name_order => 'inverted',
      :primary_name => inner_xml,
      :authority_id => att('authfilenumber'),
      :rules => att('rules'),
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_person), :names, name
    end
  end
end

class EADConverterInvalidDateTypeError < StandardError; end;
