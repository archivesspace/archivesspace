# encoding: utf-8
require_relative 'ead'
class EAD3Serializer < EADSerializer
  serializer_for :ead3

  def valid_children_of_p
    ['abbr','corpname','date','emph','expan','famname','footnote','foreign', 'function','genreform',
      'geogname','lb','list','name','num','occupation','persname','ptr','quote','ref','subject','title']
  end


  def valid_children_of_unmixed_elements(element_name)
    common_children = [ 'blockquote','chronlist','head','list','p','table' ]
    valid_children_map = {}
    standard_elements = ['accessrestrict','accruals','acqinfo','altformavail','appraisal','arrangement','bioghist',
      'custodhist','fileplan','legalstatus','odd','originalsloc','phystech','prefercite',
      'processinfo','scopecontent','userestrict']

    standard_elements.each do |e|
      valid_children_map[e] = [e] + common_children
    end

    valid_children_map['bibliography'] = [ 'archref', 'bibliography', 'bibref' ] + common_children
    valid_children_map['controlaccess'] = [ 'controlaccess', 'corpname', 'famname', 'function', 'genreform', 'geogname',
      'name', 'occupation', 'persname', 'subject', 'title' ] + common_children
    valid_children_map['controlnote'] = [ 'blockquote', 'chronlist', 'list', 'p', 'table' ]
    valid_children_map['descriptivenote'] = [ 'p' ]
    valid_children_map['editionstmt'] = [ 'edition', 'p' ]
    valid_children_map['footnote'] = [ 'blockquote', 'chronlist', 'list', 'p', 'table' ]
    valid_children_map['index'] = [ 'index', 'indexentry', 'listhead' ] + common_children
    valid_children_map['otherfindaid'] = [ 'archref', 'bibref', 'otherfindaid' ] + common_children
    valid_children_map['publicationstmt'] = [ 'address', 'date', 'num', 'p', 'publisher' ]
    valid_children_map['relatedmaterial'] = [ 'archref', 'bibref', 'relatedmaterial' ] + common_children
    valid_children_map['separatedmaterial'] = [ 'archref', 'bibref', 'separatedmaterial' ] + common_children
    valid_children_map['seriesstmt'] = [ 'num', 'p', 'titleproper' ]
    valid_children_map[element_name] || nil
  end


  def valid_children_of_mixed_elements(element_name)
    valid_children_map = {}
    valid_children_map['p'] = valid_children_of_p
    valid_children_map['archref'] = valid_children_of_p - ['list']
    valid_children_map['bibref'] = valid_children_of_p - ['list']
    ['head','date','emph','num','quote','physdesc'].each do |e|
      valid_children_map[e] = ['abbr', 'emph', 'expan', 'foreign', 'lb', 'ptr', 'ref']
    end
    valid_children_map[element_name] || nil
  end


  def closed_list_attributes
    ['actuate','align','approximate','audience','colsep','countryencoding',
      'coverage','daotype','dateencoding','dsctype','frame','langencoding','level','listtype','mark',
      'numeration','parallel','pgwide','physdescstructuredtype','relationtype','render',
      'repositoryencoding','rowsep','scriptencoding','show','unitdatetype','valign','value']
  end


  def localtype_applicable_elements
    ['abstract', 'materialspec', 'accessrestrict', 'altformavail', 'archdesc', 'container',
      'originalsloc', 'phystech', 'processinfo', 'relatedmaterial', 'separatedmaterial', 'titleproper', 'title',
      'unitid', 'unittitle', 'userestrict', 'odd', 'note', 'date', 'name', 'persname', 'famname', 'corpname',
      'subject', 'occupation', 'genreform', 'function', 'num', 'physloc', 'extent', 'descgrp']
  end


  def access_elements
    ['corpname', 'famname', 'function', 'genreform', 'geogname', 'name',
      'occupation', 'persname', 'subject', 'title']
  end


  def list_numeration_value(value)
    case value
    when 'arabic'
      'decimal'
    when 'loweralpha'
      'lower-alpha'
    when 'upperalpha'
      'upper-alpha'
    when 'lowerroman'
      'lower-roman'
    when 'upperroman'
      'upper-roman'
    else
      value
    end
  end


  # Use to specify new names for EAD 2002 attributes
  # nil value indicates attribute should be removed
  def attribute_replacements(element_name=nil)
    replacements = {
      'list' => {
        'type' => 'listtype'
      },
      'ref' => {
        'title' => 'linktitle'
      },
      'language' => {
        'scriptcode' => 'script'
      }
    }
    element_name ? replacements[element_name] : replacements
  end


  def fragment_has_unwrapped_text?(fragment_or_element)
    text = ''
    fragment_or_element.children.each do |e|
      if e.text?
        text << e.inner_text
      end
    end
    text.strip.length > 0
  end


  def has_unwrapped_text?(content)
    fragment = Nokogiri::XML::DocumentFragment.parse(content)
    fragment_has_unwrapped_text?(fragment)
  end


  # Allow plugins to hook in to record processing by providing their own
  # serialization step (a class with a 'call' method accepting the arguments
  # defined in `run_serialize_step`.

  def self.add_serialize_step(serialize_step)
    @extra_serialize_steps ||= []
    @extra_serialize_steps << serialize_step
  end


  def self.run_serialize_step(data, xml, fragments, context)
    Array(@extra_serialize_steps).each do |step|
      step.new.call(data, xml, fragments, context)
    end
  end


  def prefix_id(id)
    if id.nil? or id.empty? or id == 'null'
      ""
    elsif id =~ /^#{@id_prefix}/
      id
    else
      "#{@id_prefix}#{id}"
    end
  end


  def xml_errors(content)
    # there are message we want to ignore. annoying that java xml lib doesn't
    # use codes like libxml does...
    ignore = [ /Namespace prefix .* is not defined/, /The prefix .* is not bound/  ]
    ignore = Regexp.union(ignore)
    # the "wrap" is just to ensure that there is a psuedo root element to eliminate a "false" error
    Nokogiri::XML("<wrap>#{content}</wrap>").errors.reject { |e| e.message =~ ignore  }
  end


  def escape_ampersands(content)
    # first, find any pre-escaped entities and "mark" them by replacing & with @@
    # so something like &lt; becomes @@lt;
    # and &#1234 becomes @@#1234

    content.gsub!(/&\w+;/) {|t| t.gsub('&', '@@')}
    content.gsub!(/&#\d{4}/) {|t| t.gsub('&', '@@')}
    content.gsub!(/&#\d{3}/) {|t| t.gsub('&', '@@')}

    # now we know that all & characters remaining are not part of some pre-escaped entity, and we can escape them safely
    content.gsub!('&', '&amp;')

    # 'unmark' our pre-escaped entities
    content.gsub!(/@@\w+;/) {|t| t.gsub('@@', '&')}
    content.gsub!(/@@#\d{4}/) {|t| t.gsub('@@', '&')}
    content.gsub!(/@@#\d{3}/) {|t| t.gsub('@@', '&')}

    # only allow predefined XML entities, otherwise convert ampersand so XML will validate
    valid_entities = ['&quot;', '&amp;', '&apos;', '&lt;', '&gt;']
    content.gsub!(/&\w+;/) { |t| valid_entities.include?(t) ? t : t.gsub(/&/,'&amp;') }

    return content
  end


  def structure_children(content, parent_name = nil)

    # 4archon...
    content.gsub!("\n\t", "\n\n")

    content.strip!

    original_content = content

    content = escape_ampersands(content)

    valid_children = valid_children_of_unmixed_elements(parent_name)

    # wrap text in <p> if it isn't already
    p_wrap = lambda do |text|
      text.chomp!
      text.strip!
      if text =~ /^<p(\s|\/|>)/
        if !(text =~ /<\/p>$/)
          text += '</p>'
        end
      else
        text = "<p>#{ text }</p>"
      end
      return text
    end

    # this should only be called if the text fragment only has element children
    p_wrap_invalid_children = lambda do |text|
      text.strip!
      if valid_children
        fragment = Nokogiri::XML::DocumentFragment.parse(text)
        new_text = ''
        fragment.element_children.each do |e|
          if valid_children.include?(e.name)
            new_text << e.to_s
          else
            new_text << "<p>#{ e.to_s }</p>"
          end
        end
        return new_text
      else
        return p_wrap.call(text)
      end
    end

    if !has_unwrapped_text?(content)
      content = p_wrap_invalid_children.call(content)
    else
      return content if content.length < 1
      new_content = ''
      blocks = content.split("\n\n").select { |b| !b.strip.empty? }
      blocks.each do |b|
        if has_unwrapped_text?(b)
          new_content << p_wrap.call(b)
        else
          new_content << p_wrap_invalid_children.call(b)
        end
      end
      content = new_content
    end

    ## REMOVED 2018-09 - leaving here for future reference
    # first lets see if there are any &
    # note if there's a &somewordwithnospace , the error is EntityRef and wont
    # be fixed here...
    # if xml_errors(content).any? { |e| e.message.include?("The entity name must immediately follow the '&' in the entity reference.") }
    #   content.gsub!("& ", "&amp; ")
    # end
    # END - REMOVED 2018-09

    # in some cases adding p tags can create invalid markup with mixed content
    # just return the original content if there's still problems
    xml_errors(content).any? ? original_content : content
  end


  def strip_p(content)
    content = escape_ampersands(content)
    content.gsub("<p>", "").gsub("</p>", "").gsub("<p/>", '')
  end


  def remove_smart_quotes(content)
    content = content.gsub(/\xE2\x80\x9C/, '"').gsub(/\xE2\x80\x9D/, '"').gsub(/\xE2\x80\x98/, "\'").gsub(/\xE2\x80\x99/, "\'")
  end


  def sanitize_mixed_content(content, context, fragments, allow_p = false  )
    # remove smart quotes from text
    content = remove_smart_quotes(content)

    # br's should be self closing
    content = content.gsub("<br>", "<br/>").gsub("</br>", '')

    ## moved this to structure_children and strop_p for easier testablity
    ## leaving this reference here in case you thought it should go here
    # content = escape_ampersands(content)

    if allow_p
      content = structure_children(content, context.parent.name)
    else
      content = strip_p(content)
    end

    # convert & to @@ before generating XML fragments for processing
    content.gsub!(/&/,'@@')

    content = convert_ead2002_markup(content)

    # convert @@ back to & on return value
    content.gsub!(/@@/,'&')

    begin
      if ASpaceExport::Utils.has_html?(content)
        context.text( fragments << content )
      else
        context.text content.gsub("&amp;", "&") #thanks, Nokogiri
      end
    rescue
      context.cdata content
    end
  end


  def convert_ead2002_markup(content)

    apply_changes = lambda do |fn, fragment|
      fragment.element_children.each do |e|
        fn.(e)
        if !e.element_children.empty?
          e.element_children.each { |ec| fn.(ec) }
        end
      end
      fragment
    end

    strip_attribute_namespace_prefixes = lambda do |e|
      e.attributes.each do |k,a|
        a.name = a.name.gsub(/^[A-Za-z0-9]*\:/, '')
      end
    end

    convert_extref = lambda do |e|
      if e.name == 'extref'
        e.name = 'ref'
        e.remove_attribute('type') if e['type']
      end
    end

    convert_attribute_names = lambda do |e|
      e.attributes.each do |k,a|
        if replace = attribute_replacements(e.name)
          if new_name = replace[a.name]
            a.name = new_name
          end
        end
        if a.name == 'authfilenumber'
          a.name = 'identifier'
        end
      end
    end

    # must run after convert_attribute_names
    convert_list_attribute_values = lambda do |e|
      if e.name == 'list'
        if e['listtype']
          case e['listtype']
          when 'simple'
            e.remove_attribute('listtype')
          when 'marked'
            e['listtype'] = 'unordered'
          when 'deflist','ordered'
            # leave
          else
            e.remove_attribute('listtype')
          end
        end
        if e['numeration']
          e['numeration'] = list_numeration_value(e['numeration'])
        end
      end
    end

    convert_type_to_localtype = lambda do |e|
      if localtype_applicable_elements.include? e.name
        if a = e.attribute('type')
          a.name = 'localtype'
        end
      end
    end

    wrap_access_terms_in_part = lambda do |e|
      if access_elements.include? e.name
        e.children.each do |c|
          if c.text?
            part_wrapped_text = "<part>#{ c.inner_text }</part>"
            c.replace(part_wrapped_text)
          end
        end
      end
    end

    downcase_closed_list_attribute_values = lambda do |e|
      e.attributes.each do |k,a|
        if closed_list_attributes.include? a.name
          e[a.name] = a.value.downcase
        end
      end
    end

    strip_invalid_children_of_mixed_elements = lambda do |e|
      children = e.element_children
      if !children.empty?
        if (valid_children = valid_children_of_mixed_elements(e.name))
          children.each do |el|
            if !valid_children.include?(el.name) && el.inner_text
              el.replace( el.inner_text.gsub(/\s+/, ' ') )
            end
          end
        end
      end
    end

    strip_text_content = lambda do |e|
      if e.element_children.empty? && e.inner_text
        e.content = e.inner_text.strip
      end
    end

    temp_doc = Nokogiri::XML::Document.new
    temp_doc.encoding = "UTF-8"
    fragment = Nokogiri::XML::DocumentFragment.new(temp_doc, content)

    process_fragment = lambda do |f|
      apply_changes.(strip_attribute_namespace_prefixes, f)
      apply_changes.(convert_extref, f)
      apply_changes.(convert_attribute_names, f)
      apply_changes.(convert_list_attribute_values, f)
      apply_changes.(convert_type_to_localtype, f)
      apply_changes.(wrap_access_terms_in_part, f)
      apply_changes.(downcase_closed_list_attribute_values, f)
      apply_changes.(strip_invalid_children_of_mixed_elements, f)
      apply_changes.(strip_text_content, f)

      f.element_children.each do |e|
        process_fragment.(e)
      end
    end

    process_fragment.(fragment)

    fragment.inner_html
  end


  def strip_tags_and_sanitize(content, context, fragments)
    content.gsub!(/\<[^\>]*\>/,'')
    sanitize_mixed_content(content, context, fragments)
  end


  def stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      begin

      ead_attributes = {}

      if data.publish === false
        ead_attributes['audience'] = 'internal'
      end

      xml.ead( ead_attributes ) {

        xml.text (
          @stream_handler.buffer { |xml, new_fragments|
            serialize_control(data, xml, new_fragments)
          }
        )

        atts = {:level => data.level, :otherlevel => data.other_level}
        atts.reject! {|k, v| v.nil?}

        xml.archdesc(atts) {

          xml.did {

            unless data.title.nil?
              xml.unittitle { sanitize_mixed_content(data.title, xml, @fragments) }
            end

            xml.unitid (0..3).map{ |i| data.send("id_#{i}") }.compact.join('.')

            unless data.repo.nil? || data.repo.name.nil?
              xml.repository {
                xml.corpname {
                  xml.part {
                    sanitize_mixed_content(data.repo.name, xml, @fragments)
                  }
                }
              }
            end

            unless (languages = data.lang_materials).empty?
              serialize_languages(languages, xml, @fragments)
            end

            data.instances_with_sub_containers.each do |instance|
              serialize_container(instance, xml, @fragments)
            end

            serialize_extents(data, xml, @fragments)

            serialize_dates(data, xml, @fragments)

            serialize_did_notes(data, xml, @fragments)

            serialize_origination(data, xml, @fragments)

            if @include_unpublished
              data.external_ids.each do |exid|
                xml.unitid  ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
              end
            end


            EADSerializer.run_serialize_step(data, xml, @fragments, :did)

            # Change from EAD 2002: dao must be children of did in EAD3, not archdesc
            data.digital_objects.each do |dob|
              serialize_digital_object(dob, xml, @fragments)
            end

          }# </did>

          serialize_nondid_notes(data, xml, @fragments)

          serialize_bibliographies(data, xml, @fragments)

          serialize_indexes(data, xml, @fragments)

          serialize_controlaccess(data, xml, @fragments)

          EADSerializer.run_serialize_step(data, xml, @fragments, :archdesc)

          xml.dsc {

            data.children_indexes.each do |i|
              xml.text( @stream_handler.buffer {
                |xml, new_fragments| serialize_child(data.get_child(i), xml, new_fragments)
                }
              )
            end
          }
        }
      }

      rescue => e
        xml.text  "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF YOUR RESOURCE. THE FOLLOWING INFORMATION MAY HELP:\n
                  MESSAGE: #{e.message.inspect}  \n
                  TRACE: #{e.backtrace.inspect} \n "
      end
    end

    # Add xml-model for rng
    # Make this conditional if XSD or DTD are requested
    xmlmodel_content = 'href="https://raw.githubusercontent.com/SAA-SDT/EAD3/master/ead3.rng"
      type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"'

    xmlmodel = Nokogiri::XML::ProcessingInstruction.new(builder.doc, "xml-model", xmlmodel_content)
    builder.doc.root.add_previous_sibling(xmlmodel)
    builder.doc.root.add_namespace nil, 'http://ead3.archivists.org/schema/'

    Enumerator.new do |y|
      @stream_handler.stream_out(builder, @fragments, y)
    end
  end # END stream


  def serialize_control(data, xml, fragments)
    control_atts = {
      repositoryencoding: "iso15511",
      countryencoding: "iso3166-1",
      dateencoding: "iso8601",
      relatedencoding: "marc",
      langencoding: "iso639-2b",
      scriptencoding: "iso15924"
    }.reject{|k,v| v.nil? || v.empty? || v == "null"}

    xml.control(control_atts) {

      ark_url = AppConfig[:arks_enabled] ? ArkName::get_ark_url(data.id, :resource) : nil

      ins_url = ark_url.nil? ? data.ead_location : ark_url

      recordid_atts = {
        instanceurl: ins_url
      }

      xml.recordid(recordid_atts) {
        xml.text(data.ead_id)
      }

      xml.filedesc {

        xml.titlestmt {
          # titleproper
          titleproper = ""
          titleproper += "#{data.finding_aid_title} " if data.finding_aid_title
          titleproper += "#{data.title}" if ( data.title && titleproper.empty? )
          xml.titleproper {  strip_tags_and_sanitize(titleproper, xml, fragments) }

          # titleproper (filing)
          unless data.finding_aid_filing_title.nil?
            xml.titleproper("localtype" => "filing") {
              sanitize_mixed_content(data.finding_aid_filing_title, xml, fragments)
            }
          end

          # subtitle
          unless data.finding_aid_subtitle.nil?
            xml.subtitle {
              sanitize_mixed_content(data.finding_aid_subtitle, xml, fragments)
            }
          end

          # author
          unless data.finding_aid_author.nil?
            xml.author {
              sanitize_mixed_content(data.finding_aid_author, xml, fragments)
            }
          end

          # sponsor
          unless data.finding_aid_sponsor.nil?
            xml.sponsor {
              sanitize_mixed_content( data.finding_aid_sponsor, xml, fragments)
            }
          end
        }

        unless data.finding_aid_edition_statement.nil?
          xml.editionstmt {
            sanitize_mixed_content(data.finding_aid_edition_statement, xml, fragments, true )
          }
        end

        xml.publicationstmt {

          xml.publisher { sanitize_mixed_content(data.repo.name, xml, fragments) }

          repo_addresslines = data.addresslines_keyed

          unless repo_addresslines.empty?
            xml.address {

              repo_addresslines.each do |key, line|
                if ['telephone', 'email'].include?(key)
                  addressline_atts = { localtype: key }
                  xml.addressline(addressline_atts) {
                    sanitize_mixed_content(line, xml, fragments)
                  }
                else
                  xml.addressline { sanitize_mixed_content( line, xml, fragments) }
                end
              end

              if data.repo.url
                xml.addressline {
                  xml.ref ({ href: data.repo.url, linktitle: data.repo.url, show: "new" }) {
                    xml.text(data.repo.url)
                  }
                }
              end
            }
          end

          if (data.finding_aid_date)
            xml.date { sanitize_mixed_content( data.finding_aid_date, xml, fragments) }
          end

          num = (0..3).map { |i| data.send("id_#{i}") }.compact.join('.')
          unless num.empty?
            xml.num() {
              xml.text(num)
            }
          end

          if data.repo.image_url
            xml.p {
              xml.ptr ({
                href: data.repo.image_url,
                actuate: "onload",
                show: "embed"
              })
            }
          end
        }

        if (data.finding_aid_series_statement)
          xml.seriesstmt {
            sanitize_mixed_content( data.finding_aid_series_statement, xml, fragments, true )
          }
        end

        if ( data.finding_aid_note )
          xml.notestmt {
            xml.controlnote {
              sanitize_mixed_content( data.finding_aid_note, xml, fragments, true )
            }
          }
        end
      } # END filedesc

      xml.maintenancestatus( { value: 'derived' } )

      maintenanceagency_atts = {
        countrycode: data.repo.country
      }.delete_if { |k,v| v.nil? || v.empty? }

      xml.maintenanceagency(maintenanceagency_atts) {

        unless data.repo.org_code.nil?
          agencycode = data.repo.country ? "#{data.repo.country}-" : ''
          agencycode += data.repo.org_code
          xml.agencycode() {
            xml.text(agencycode)
          }
        end

        xml.agencyname() {
          xml.text(data.repo.name)
        }
      }

      unless data.finding_aid_language.nil?
        xml.languagedeclaration() {

          xml.language({ langcode: "#{data.finding_aid_language}"}) {
            xml.text(I18n.t("enumerations.language_iso639_2.#{data.finding_aid_language}"))
          }

          xml.script({ scriptcode: "#{data.finding_aid_script}" }) {
            xml.text(I18n.t("enumerations.script_iso15924.#{data.finding_aid_script}"))
          }

          unless data.finding_aid_language_note.nil?
            xml.descriptivenote {
              sanitize_mixed_content(data.finding_aid_language_note, xml, fragments, true)
            }
          end

        }
      end

      unless data.finding_aid_description_rules.nil?
        xml.conventiondeclaration {
          xml.abbr {
            xml.text(data.finding_aid_description_rules)
          }
          xml.citation {
            xml.text(I18n.t("enumerations.resource_finding_aid_description_rules.#{ data.finding_aid_description_rules}"))
          }
        }
      end

      unless data.finding_aid_status.nil?
        xml.localcontrol( { localtype: 'findaidstatus'} ) {
          xml.term() {
            xml.text(data.finding_aid_status)
          }
        }
      end

      xml.maintenancehistory() {
        xml.maintenanceevent() {
          xml.eventtype( { value: 'derived' } ) {}
          xml.eventdatetime() {
            xml.text(DateTime.now.to_s)
          }
          xml.agenttype( { value: 'machine' } ) {}
          xml.agent() {
            xml.text("ArchivesSpace #{ ASConstants.VERSION }")
          }
          xml.eventdescription {
            xml.text("This finding aid was produced using ArchivesSpace on #{ DateTime.now.strftime('%A %B %e, %Y at %H:%M') }")
          }
        }

        export_rs = @include_unpublished ? data.revision_statements : data.revision_statements.reject { |rs| !rs['publish'] }
        if export_rs.length > 0
          export_rs.each do |rs|
            xml.maintenanceevent(rs['publish'] ? nil : {:audience => 'internal'}) {
              xml.eventtype( { value: 'revised' } ) {}
              xml.eventdatetime() {
                xml.text(rs['date'].to_s)
              }
              xml.agenttype( { value: 'unknown' } ) {}
              xml.agent() {}
              xml.eventdescription() {
                sanitize_mixed_content( rs['description'], xml, fragments)
              }
            }
          end
        end
      }
    }
  end # END serialize_control


  def serialize_extents(obj, xml, fragments)
    if obj.extents.length
      obj.extents.each do |e|
        next if e["publish"] === false && !@include_unpublished

        # physdescstructuredtype is based on extent_type
        # These mappings only account for the default value options
        physdescstructured_atts = { coverage: e['portion'] }

        if e["publish"] === false
          physdescstructured_atts[:audience] = 'internal'
        end

        case e['extent_type']
        when 'cassettes','leaves','photographic_prints','photographic_slides','reels','sheets','volumes'
          physdescstructured_atts[:physdescstructuredtype] = 'materialtype'
        when 'cubic_feet','linear_feet'
          physdescstructured_atts[:physdescstructuredtype] = 'spaceoccupied'
        when 'gigabytes','megabytes','terabytes'
          physdescstructured_atts[:physdescstructuredtype] = 'otherphysdescstructuredtype'
        else
          physdescstructured_atts[:physdescstructuredtype] = 'spaceoccupied'
        end

        xml.physdescstructured(physdescstructured_atts) {
          if e['number']
            xml.quantity() {
              xml.text(e['number'])
            }
          end

          if e['extent_type']
            xml.unittype() {
              xml.text( I18n.t('enumerations.extent_extent_type.' + e['extent_type'], :default => e['extent_type']) )
            }
          end

          if e['physical_details']
            xml.physfacet() {
              sanitize_mixed_content(e['physical_details'],xml, fragments)
            }
          end

          if e['dimensions']
            xml.dimensions() {
               sanitize_mixed_content(e['dimensions'],xml, fragments)
            }
          end
        }

        if e['container_summary']
          xml.physdesc({ localtype: 'container_summary' }) {
            sanitize_mixed_content( e['container_summary'], xml, fragments)
          }
        end
      end
    end
  end


  def serialize_dates(obj, xml, fragments)
    add_unitdate = Proc.new do |value, context, fragments, atts={}|
      context.unitdate(atts) {
        sanitize_mixed_content( value, context, fragments )
      }
    end

    obj.dates.each do |date|
      next if date["publish"] === false && !@include_unpublished

      date_atts = {
        certainty: date['certainty'] ? date['certainty'] : nil,
        era: date['era'] ? date['era'] : nil,
        calendar: date['calendar'] ? date['calendar'] : nil,
        audience: date['publish'] === false ? 'internal' : nil
      }

      unless date['date_type'].nil?
        date_atts[:unitdatetype] = date['date_type'] == 'bulk' ? 'bulk' : 'inclusive'
      end

      date_atts.delete_if { |k,v| v.nil? }

      if date['begin'] || date['end']

        xml.unitdatestructured(date_atts) {

          if date['date_type'] == 'single' && date['begin']

            xml.datesingle( { standarddate: date['begin'] } ) {
              value = date['expression'].nil? ? date['begin'] : date['expression']
              xml.text(value)
            }

          else

            xml.daterange() {
              if date['begin']
                xml.fromdate( { standarddate: date['begin'] } ) {
                  xml.text(date['begin'])
                }
              end
              if date['end']
                xml.todate( { standarddate: date['end'] } ) {
                  xml.text(date['end'])
                }
              end
            }
          end
        }

        if date['begin'] && date['end'] && date['expression']
          add_unitdate.call(date['expression'], xml, fragments, date_atts)
        end

      elsif date['expression']
        add_unitdate.call(date['expression'], xml, fragments, date_atts)
      end
    end
  end


  def strip_invalid_children_from_note_content(content, parent_element_name)
    # convert & to @@ before generating XML fragment for processing
    content.gsub!(/&/,'@@')
    fragment = Nokogiri::XML::DocumentFragment.parse(content)
    children = fragment.element_children

    if !children.empty?
      if valid_children = valid_children_of_mixed_elements(parent_element_name)
        children.each do |e|
          if !valid_children.include?(e.name) && e.inner_text
            e.replace( e.inner_text.gsub(/\s+/, ' ') )
          end
        end
      end
    end

    # convert @@ back to & on return value
    fragment.inner_html.gsub(/@@/,'&')
  end


  def serialize_did_notes(data, xml, fragments)
    data.notes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      # SEE backend/app/exporters/lib/export_helpers.rb - did note types valid for both EAD 2002 and EAD3
      next unless data.did_note_types.include?(note['type'])

      atts = {
        audience: note["publish"] === false ? 'internal' : nil,
        id: prefix_id(note['persistent_id'].gsub(/\s/,'_'))
      }
      atts.delete_if { |k,v| v.nil? || v.empty? || v == "null" }

      append_note_content = Proc.new do |note, context, fragments, parent_element_name|
        content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
        content = strip_invalid_children_from_note_content(content, parent_element_name)
        sanitize_mixed_content( content, context, fragments, ASpaceExport::Utils.include_p?(note['type']) )
      end

      case note['type']
      when 'dimensions', 'physfacet'
        atts[:label] = note['label'] if note['label']
        xml.physdesc(atts) {
          append_note_content.(note, xml, fragments, 'physdesc')
        }
      when 'physdesc'
        atts[:label] = note['label'] if note['label']
        xml.send(note['type'], atts) {
          append_note_content.(note, xml, fragments, note['type'])
        }
      when 'langmaterial'
        xml.langmaterial(atts) {
          xml.language() {
            append_note_content.(note, xml, fragments, 'language')
          }
        }
      else
        xml.send(note['type'], atts) {
          append_note_content.(note, xml, fragments, note['type'])
        }
      end

    end
  end

  def serialize_languages(languages, xml, fragments)
    language_vals = languages.map{|l| l['language_and_script']}.compact
    # Language and Script subrecords with recorded values in both fields should be exported as <languageset> elements.
    xml.langmaterial {
      language_vals.map {|language|
        if !language['script']
          xml.language(:langcode => language['language']) {
            xml.text I18n.t("enumerations.language_iso639_2.#{language['language']}", :default => language['language'])
            }
        # Language and Script subrecord entries with only a Language value record should be exported as <language> elements.
        else
          xml.languageset {
           xml.language(:langcode => language['language']) {
            xml.text I18n.t("enumerations.language_iso639_2.#{language['language']}", :default => language['language'])
            }
            xml.script(:scriptcode => language['script']) {
             xml.text I18n.t("enumerations.script_iso15924.#{language['script']}", :default => language['script'])
            }
          }
        end
      }
      # Language Text subrecord content should be exported as a <descriptivenote> element
      language_notes = languages.map {|l| l['notes']}.compact.reject {|e|  e == [] }.flatten
      if !language_notes.empty?
        language_notes.each do |note|
          content = ASpaceExport::Utils.extract_note_text(note)
          xml.descriptivenote {
            sanitize_mixed_content(content, xml, fragments, true)
          }
        end
      end
    }
  end


  def serialize_note_content(note, xml, fragments)
    return if note["publish"] === false && !@include_unpublished
    content = note["content"]

    atts = {
      audience: note['publish'] === false ? 'internal' : nil,
      id: prefix_id(note['persistent_id'].gsub(/\s/,'_'))
    }
    atts.delete_if { |k,v| v.nil? || v.empty? || v == "null" }

    head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note['type']}", :default => note['type'])

    content, head_text = extract_head_text(content, head_text)

    xml.send(note['type'], atts) {
      xml.head { sanitize_mixed_content(head_text, xml, fragments) } unless ASpaceExport::Utils.headless_note?(note['type'], content )
      sanitize_mixed_content(content, xml, fragments, ASpaceExport::Utils.include_p?(note['type']) ) if content
      if note['subnotes']
        serialize_subnotes(note['subnotes'], xml, fragments, ASpaceExport::Utils.include_p?(note['type']))
      end
    }
  end


  def serialize_nondid_notes(data, xml, fragments)
    data.notes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      next if note['internal']
      next if note['type'].nil?
      next unless data.archdesc_note_types.include?(note['type'])
      serialize_note_content(note, xml, fragments)
    end
  end


  def serialize_origination(data, xml, fragments)
    unless data.creators_and_sources.nil?
      data.creators_and_sources.each do |link|
        agent = link['_resolved']
        link['role'] == 'creator' ? role = link['role'].capitalize : role = link['role']
        relator = link['relator']
        sort_name = agent['display_name']['sort_name']
        rules = agent['display_name']['rules']
        source = agent['display_name']['source']
        authfilenumber = agent['display_name']['authority_id']
        node_name = case agent['agent_type']
                    when 'agent_person'; 'persname'
                    when 'agent_family'; 'famname'
                    when 'agent_corporate_entity'; 'corpname'
                    when 'agent_software'; 'name'
                    end
        xml.origination(:label => role) {

          atts = {:relator => relator, :source => source, :rules => rules, :identifier => authfilenumber}

          atts.reject! {|k, v| v.nil?}

          xml.send(node_name, atts) {
            xml.part() {
              sanitize_mixed_content(sort_name, xml, fragments )
            }
          }
        }
      end
    end
  end


  # this extracts <head> content and returns it. optionally, you can provide a
  # backup text node that will be returned if there is no <head> nodes in the
  # content
  def extract_head_text(content, backup = "")
    content ||= ""
    match = content.strip.match(/<head( [^<>]+)?>(.+?)<\/head>/)
    if match.nil? # content has no head so we return it as it
      return [content, backup ]
    else
      [ content.gsub(match.to_a.first, ''), match.to_a.last]
    end
  end


  def serialize_child(data, xml, fragments, c_depth = 1)
    begin
    return if data["publish"] === false && !@include_unpublished
    return if data["suppressed"] === true

    tag_name = @use_numbered_c_tags ? :"c#{c_depth.to_s.rjust(2, '0')}" : :c

    atts = {:level => data.level, :otherlevel => data.other_level, :id => prefix_id(data.ref_id)}

    if data.publish === false
      atts[:audience] = 'internal'
    end

    atts.reject! {|k, v| v.nil?}
    xml.send(tag_name, atts) {

      xml.did {
        if (val = data.title)
          xml.unittitle {  sanitize_mixed_content( val,xml, fragments) }
        end

        if AppConfig[:arks_enabled]
          ark_url = ArkName::get_ark_url(data.id, :archival_object)
          if ark_url
            # <unitid><ref href=”ARK” show="new" actuate="onload">ARK</ref></unitid>
            xml.unitid {
              xml.ref ({"href" => ark_url,
                        "actuate" => "onload",
                        "show" => "new"
                        }) { xml.text 'Archival Resource Key' }
                        }
          end
        end

        if !data.component_id.nil? && !data.component_id.empty?
          xml.unitid data.component_id
        end

        if @include_unpublished
          data.external_ids.each do |exid|
            xml.unitid  ({ "audience" => "internal",  "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
          end
        end

        serialize_origination(data, xml, fragments)
        serialize_extents(data, xml, fragments)
        serialize_dates(data, xml, fragments)
        serialize_did_notes(data, xml, fragments)

        unless (languages = data.lang_materials).empty?
          serialize_languages(languages, xml, fragments)
        end

        EADSerializer.run_serialize_step(data, xml, fragments, :did)

        data.instances_with_sub_containers.each do |instance|
          serialize_container(instance, xml, @fragments)
        end

        if @include_daos
          data.instances_with_digital_objects.each do |instance|
            serialize_digital_object(instance['digital_object']['_resolved'], xml, fragments)
          end
        end
      }

      serialize_nondid_notes(data, xml, fragments)
      serialize_bibliographies(data, xml, fragments)
      serialize_indexes(data, xml, fragments)
      serialize_controlaccess(data, xml, fragments)
      EADSerializer.run_serialize_step(data, xml, fragments, :archdesc)

      data.children_indexes.each do |i|
        xml.text(
                 @stream_handler.buffer {|xml, new_fragments|
                   serialize_child(data.get_child(i), xml, new_fragments, c_depth + 1)
                 }
                 )
      end
    }
    rescue => e
      xml.text "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF ARCHIVAL OBJECTS. THE FOLLOWING INFORMATION MAY HELP:\n

                MESSAGE: #{e.message.inspect}  \n
                TRACE: #{e.backtrace.inspect} \n "
    end
  end


  def serialize_controlaccess(data, xml, fragments)

    if (data.controlaccess_subjects.length + data.controlaccess_linked_agents.length) > 0
      xml.controlaccess {

        data.controlaccess_subjects.each do |node_data|

          if node_data[:atts]['authfilenumber']
            node_data[:atts]['identifier'] = node_data[:atts]['authfilenumber'].clone
            node_data[:atts].delete('authfilenumber')
          end

          xml.send(node_data[:node_name], node_data[:atts]) {
            xml.part() {
              sanitize_mixed_content( node_data[:content], xml, fragments, ASpaceExport::Utils.include_p?(node_data[:node_name]) )
            }
          }
        end

        data.controlaccess_linked_agents.each do |node_data|

          if node_data[:atts][:role]
            node_data[:atts][:relator] = node_data[:atts][:role]
            node_data[:atts].delete(:role)
          end

          if node_data[:atts][:authfilenumber]
            node_data[:atts][:identifier] = node_data[:atts][:authfilenumber].clone
            node_data[:atts].delete(:authfilenumber)
          end

          xml.send(node_data[:node_name], node_data[:atts]) {
            xml.part() {
              sanitize_mixed_content( node_data[:content], xml, fragments,ASpaceExport::Utils.include_p?(node_data[:node_name]) )
            }
          }
        end

      } #</controlaccess>
    end
  end


  def serialize_subnotes(subnotes, xml, fragments, include_p = true)
    subnotes.each do |sn|
      next if sn["publish"] === false && !@include_unpublished

      audatt = sn["publish"] === false ? {:audience => 'internal'} : {}

      title = sn['title']

      case sn['jsonmodel_type']
      when 'note_text'
        sanitize_mixed_content(sn['content'], xml, fragments, include_p )
      when 'note_chronology'
        xml.chronlist(audatt) {
          xml.head { sanitize_mixed_content(title, xml, fragments) } if title

          sn['items'].each do |item|
            xml.chronitem {
              if (val = item['event_date'])
                xml.datesingle { sanitize_mixed_content( val, xml, fragments) }
              end
              if item['events'] && !item['events'].empty?
                xml.chronitemset {
                  item['events'].each do |event|
                    xml.event { sanitize_mixed_content(event, xml, fragments) }
                  end
                }
              end
            }
          end
        }
      when 'note_orderedlist'
        atts = {:listtype => 'ordered', :numeration => sn['enumeration']}.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)

        atts[:numeration] = list_numeration_value(atts[:numeration])

        xml.list(atts) {
          xml.head { sanitize_mixed_content(title, xml, fragments) }  if title

          sn['items'].each do |item|
            xml.item { sanitize_mixed_content(item,xml, fragments)}
          end
        }
      when 'note_definedlist'
        xml.list({:listtype => 'deflist'}.merge(audatt)) {
          xml.head { sanitize_mixed_content(title,xml, fragments) }  if title

          sn['items'].each do |item|
            xml.defitem {
              xml.label { sanitize_mixed_content(item['label'], xml, fragments) } if item['label']
              xml.item { sanitize_mixed_content(item['value'],xml, fragments )} if item['value']
            }
          end
        }
      end
    end
  end


  def serialize_container(inst, xml, fragments)
    atts = {}

    sub = inst['sub_container']
    top = sub['top_container']['_resolved']

    # top container
    atts[:id] = prefix_id(SecureRandom.hex)
    last_id = atts[:id]
    atts[:localtype] = top['type']
    text = top['indicator']
    atts[:label] = I18n.t("enumerations.instance_instance_type.#{inst['instance_type']}",
                          :default => inst['instance_type'])
    if top['barcode']
      atts[:containerid] = "#{top['barcode']}"
    end

    if (cp = top['container_profile'])
      atts[:altrender] = cp['_resolved']['url'] || cp['_resolved']['name']
    end

    xml.container(atts) {
      sanitize_mixed_content(text, xml, fragments)
    }

    # sub container
    (2..3).each do |n|
      atts = {}

      next unless sub["type_#{n}"]

      atts[:id] = prefix_id(SecureRandom.hex)
      atts[:parent] = last_id
      last_id = atts[:id]

      atts[:localtype] = sub["type_#{n}"]
      text = sub["indicator_#{n}"]

      xml.container(atts) {
        sanitize_mixed_content(text, xml, fragments)
      }
    end
  end


  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    return if digital_object["suppressed"] === true

    file_versions = digital_object['file_versions']
    title = digital_object['title']
    date = digital_object['dates'][0] || {}

    atts = {}

    content = ""
    content << title if title
    content << ": " if date['expression'] || date['begin']
    if date['expression']
      content << date['expression']
    elsif date['begin']
      content << date['begin']
      if date['end'] != date['begin']
        content << "-#{date['end']}"
      end
    end

    atts['linktitle'] = digital_object['title'] if digital_object['title']

    if digital_object['digital_object_type']
      atts['daotype'] = 'otherdaotype'
      atts['otherdaotype'] = digital_object['digital_object_type']
    else
      atts['daotype'] = 'unknown'
    end

    if file_versions.empty?
      atts['href'] = digital_object['digital_object_id']
      atts['actuate'] = 'onrequest'
      atts['show'] = 'new'
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object)
      xml.dao(atts) {
        xml.descriptivenote { sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    else
      file_versions.each do |file_version|
        atts['href'] = file_version['file_uri'] || digital_object['digital_object_id']
        atts['actuate'] = (file_version['xlink_actuate_attribute'].respond_to?(:downcase) && file_version['xlink_actuate_attribute'].downcase) || 'onrequest'
        atts['show'] = (file_version['xlink_show_attribute'].respond_to?(:downcase) && file_version['xlink_show_attribute'].downcase) || 'new'
        atts['localtype'] = file_version['use_statement'] if file_version['use_statement']
        atts['audience'] = 'internal' unless is_digital_object_published?(digital_object, file_version)
        xml.dao(atts) {
          xml.descriptivenote { sanitize_mixed_content(content, xml, fragments, true) } if content
        }
      end
    end
  end


  def serialize_bibliographies(data, xml, fragments)
    data.bibliographies.each do |note|
      next if note["publish"] === false && !@include_unpublished
      content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
      note_type = note["type"] ? note["type"] : "bibliography"
      head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note_type}", :default => note_type )

      atts = {
        audience: note["publish"] === false ? 'internal' : nil,
        id: prefix_id(note['persistent_id'].gsub(/\s/,'_'))
      }
      atts.delete_if { |k,v| v.nil? || v.empty? || v == "null" }

      xml.bibliography(atts) {
        xml.head { sanitize_mixed_content(head_text, xml, fragments) }
        sanitize_mixed_content( content, xml, fragments, true)
        note['items'].each do |item|
          xml.bibref { sanitize_mixed_content( item, xml, fragments) }  unless item.empty?
        end
      }
    end
  end


  def serialize_indexes(data, xml, fragments)
    data.indexes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
      head_text = nil

      if note['label']
        head_text = note['label']
      elsif note['type']
        head_text = I18n.t("enumerations._note_types.#{note['type']}", :default => note['type'])
      end

      atts = {
        audience: note["publish"] === false ? 'internal' : nil,
        id: prefix_id(note['persistent_id'].gsub(/\s/,'_'))
      }
      atts.delete_if { |k,v| v.nil? || v.empty? || v == "null" }

      content, head_text = extract_head_text(content, head_text)

      xml.index(atts) {
        xml.head { sanitize_mixed_content(head_text,xml,fragments ) } unless head_text.nil?

        sanitize_mixed_content(content, xml, fragments, true)

        note['items'].each do |item|
          next unless (node_name = data.index_item_type_map[item['type']])
          xml.indexentry {

            atts = item['reference'] ? {:target => prefix_id( item['reference']) } : {}

            if (val = item['value'])
              xml.send(node_name) {
                xml.part() {
                  sanitize_mixed_content(val, xml, fragments )
                }
              }
            end

            if (val = item['reference_text'])
              xml.ref(atts) {
                sanitize_mixed_content( val, xml, fragments)
              }
            end
          }
        end
      }
    end
  end

end
