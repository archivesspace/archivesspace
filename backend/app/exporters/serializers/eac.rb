class EACSerializer < ASpaceExport::Serializer
  serializer_for :eac
  
  def serialize(eac, opts = {})

    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      _eac(eac, xml)     
    end
    
    builder.to_xml   
  end
  
  private

  # wrapper around nokogiri that creates a node without empty attrs and nodes
  def create_node(xml, node_name, attrs, text)
    unless text.nil? || text.empty?
      attrs = attrs.reject {|k, v| v.nil? }
      xml.send(node_name, attrs) {
        xml.text text
      }
    end
  end

  def filled_out?(values, mode = :some)
    if mode == :all
      values.inject {|memo, v| memo && (!v.nil? && !v.empty?) }
    else mode == :some
      values.inject {|memo, v| memo || (!v.nil? && !v.empty?) }
    end
  end

  def clean_attrs(attrs)
    attrs.reject {|k, v| v.nil? }
  end
  
  def _eac(obj, xml)  
    json = obj.json
    xml.send("eac-cpf", {'xmlns' => 'urn:isbn:1-931666-33-4',
               "xmlns:html" => "http://www.w3.org/1999/xhtml",
               "xmlns:xlink" => "http://www.w3.org/1999/xlink",
               "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
               "xsi:schemaLocation" => "urn:isbn:1-931666-33-4 http://eac.staatsbibliothek-berlin.de/schema/cpf.xsd",
               "xml:lang" => "eng"}) {
      _control(json, xml)
      _cpfdesc(json, xml, obj)
    }
  end
  
  def _control(json, xml)
    xml.control {
      # AGENT_RECORD_IDENTIFIERS
      if json['agent_record_identifiers']
        json['agent_record_identifiers'].each do |ari|
          if ari["primary_identifier"] == true
            xml.recordId ari["record_identifier"]
          else
            attrs = {:localType => ari["identifier_type_enum"]}
            create_node(xml, "otherRecordId", attrs, ari["record_identifier"])
          end
        end
      end

      # AGENT_RECORD_CONTROLS
      if json['agent_record_controls'] && json['agent_record_controls'].any?
        arc = json['agent_record_controls'].first
  
        create_node(xml, "maintenanceStatus", {}, arc['maintenance_status_enum'])
        create_node(xml, "publicationStatus", {}, arc['publication_status_enum'])
  
        if filled_out?([arc["maintenance_agency"], arc["agency_name"], arc["maintenance_agency_note"]])

          xml.maintenanceAgency {
            create_node(xml, "agencyCode", {}, arc["maintenance_agency"]) if AppConfig[:export_eac_agency_code]
            create_node(xml, "agencyName", {}, arc["agency_name"])
            create_node(xml, "descriptiveNote", {}, arc["maintenance_agency_note"])
          }
        end

        if filled_out?([arc["language"], arc["language_note"]])
          xml.languageDeclaration {
            language_attrs = {:languageCode => arc["language"]}
            script_attrs = {:scriptCode => arc["script"]}
            create_node(xml, "language", language_attrs, arc["language"])
            create_node(xml, "script", script_attrs, arc["script"])
            create_node(xml, "descriptiveNote", {}, arc["language_note"])
          }
        end
      end

      # AGENT_CONVENTIONS_DECLARATIONS
      if json['agent_conventions_declarations']
        json['agent_conventions_declarations'].each do |cd|

          if filled_out?([cd["name_rule"], cd['citation'], cd['descriptive_note']])
            xml.conventionDeclaration {
              xlink_attrs = {
                "xlink:href" => cd['file_uri'],
                "xlink:actuate" => cd['file_version_xlink_actuate_attribute'],
                "xlink:show" => cd['file_version_xlink_show_attribute'],
                "xlink:title" => cd['xlink_title_attribute'],
                "xlink:role" => cd['xlink_role_attribute'],
                "xlink:arcrole" => cd['xlink_arcrole_attribute'],
                "lastDateTimeVerified" => cd['last_verified_date'] 
              }

              create_node(xml, "abbreviation", {}, cd["name_rule"])
              create_node(xml, "citation", xlink_attrs, cd["citation"])
              create_node(xml, "descriptiveNote", {}, cd["descriptive_note"])
            }
          end
        end
      end

      # MAINTENANCE_HISTORY
      if json['agent_maintenance_histories']
        xml.maintenanceHistory {
          json['agent_maintenance_histories'].each do |mh|

            if filled_out?([mh['maintenance_event_type_enum'], mh['event_date'], mh['maintenance_agent_type_enum'], mh['agent'], mh['descriptive_note']])

              xml.maintenanceEvent {
                create_node(xml, "eventType", {}, mh['maintenance_event_type_enum'])

                xml.eventDateTime(:standardDateTime => mh['event_date']) if filled_out?([mh['event_date']], :all)

                create_node(xml, "agentType", {}, mh['maintenance_agent_type_enum'])

                create_node(xml, "agent", {}, mh['agent'])
                create_node(xml, "eventDescription", {}, mh['descriptive_note'])
              }
            end
          end  
        }
      end

      #AGENT_SOURCES
      if json['agent_sources'] && json['agent_sources'].any?
        xml.sources {
          json['agent_sources'].each do |as|
            xlink_attrs = {
              "xlink:href" => as['file_uri'],
              "xlink:actuate" => as['file_version_xlink_actuate_attribute'],
              "xlink:show" => as['file_version_xlink_show_attribute'],
              "xlink:title" => as['xlink_title_attribute'],
              "xlink:role" => as['xlink_role_attribute'],
              "xlink:arcrole" => as['xlink_arcrole_attribute'],
              "lastDateTimeVerified" => as['last_verified_date']
            }

            if filled_out?([as['source_entry'], as['descriptive_note']])
              xml.source(clean_attrs(xlink_attrs)) {
                create_node(xml, "sourceEntry", {}, as['source_entry'])
                create_node(xml, "descriptiveNote", {}, as['descriptive_note'])
              }
            end
          end
        }
      end
    } # of xml.control
  end # of #_control
  
  def _cpfdesc(json, xml, obj)
    xml.cpfDescription {
      
      xml.identity {
        
        # AGENT_IDENTIFIERS
        if json['agent_identifiers'].any?
          json['agent_identifiers'].each do |ad|
            attrs = {:localType => ad['identifier_type_enum']}

            create_node(xml, "entityId", attrs, ad['entity_identifier'])
          end
        end

        # ENTITY_TYPE
        entity_type = json['jsonmodel_type'].sub(/^agent_/, "").sub('corporate_entity', 'corporateBody')
        
        xml.entityType entity_type

        # NAMES
        json['names'].each do |name|
          # NAMES WITH PARALLEL
          if name['parallel_names'] && name['parallel_names'].any?
            xml.nameEntryParallel {
              _build_name_entry(name, xml, json, obj)

              name['parallel_names'].each do |pname|
                _build_name_entry(pname, xml, json, obj)
              end
            }

          # NAMES NO PARALLEL
          else
            _build_name_entry(name, xml, json, obj)
          end
        end
      } # end of xml.identity


      xml.description {
        # DATES_OF_EXISTENCE
        if json['dates_of_existence'] && json['dates_of_existence'].any?
          xml.existDates {
            json['dates_of_existence'].each do |date|
              if date['date_type_enum'] == 'single'
                _build_date_single(date, xml)
              else
                _build_date_range(date, xml)
              end
            end
          }
        end

        # LANGUAGES USED
        if json['used_languages'] && json['used_languages'].any?
          xml.languagesUsed {
            json['used_languages'].each do |lang|

              if filled_out?([lang['language'], lang['script']])
                language = I18n.t("enumerations.language_iso639_2.#{lang['language']}")
                script = I18n.t("enumerations.script_iso15924.#{lang['script']}") 
                lang_attrs = {"languageCode" => lang['language']}
                script_attrs = {"scriptCode" => lang['script']}


                xml.languageUsed {
                  create_node(xml, "language", lang_attrs, language)
                  create_node(xml, "script", script_attrs, script)
                }

              end
             
              lang['notes'].each do |n|
                create_node(xml, "descriptiveNote", {}, n['content'])
              end
            end
          }
        end

        # PLACES
        if json['agent_places'] && json['agent_places'].any?
          xml.places {
            json['agent_places'].each do |place|
              subject = place['subjects'].first['_resolved']
              entry_attrs = {:vocabularySource => subject['source']}

              if filled_out?([place['place_role_enum'], subject['terms'].first['term']])
                xml.place {
                  create_node(xml, "placeRole", {}, place['place_role_enum'])
                  create_node(xml, "placeEntry", entry_attrs, subject['terms'].first['term'])

                  place['dates'].each do |date|
                    if date['date_type_enum'] == 'single'
                      _build_date_single(date, xml)
                    else
                      _build_date_range(date, xml)
                    end
                  end

                  place['notes'].each do |n|
                    create_node(xml, "descriptiveNote", {}, n['content'])
                  end
                } 
              end
            end
          }
        end

        # OCCUPATIONS
        if json['agent_occupations'] && json['agent_occupations'].any?
          xml.occupations {
            json['agent_occupations'].each do |occupation|
              subject = occupation['subjects'].first['_resolved']

              if filled_out?([subject['terms'].first['term']])

                xml.occupation {
                  create_node(xml, "term", {}, subject['terms'].first['term'])

                  occupation['dates'].each do |date|
                    if date['date_type_enum'] == 'single'
                      _build_date_single(date, xml)
                    else
                      _build_date_range(date, xml)
                    end
                  end

                  occupation['notes'].each do |n|
                    create_node(xml, "descriptiveNote", {}, n['content'])
                  end
                }
              end
            end
          }
        end

        # FUNCTIONS
        if json['agent_functions'] && json['agent_functions'].any?
          xml.functions {
            json['agent_functions'].each do |function|
              subject = function['subjects'].first['_resolved']

              if filled_out?([subject['terms'].first['term']])

                xml.function {
                  create_node(xml, "term", {}, subject['terms'].first['term'])

                  function['dates'].each do |date|
                    if date['date_type_enum'] == 'single'
                      _build_date_single(date, xml)
                    else
                      _build_date_range(date, xml)
                    end
                  end

                  function['notes'].each do |n|
                    create_node(xml, "descriptiveNote", {}, n['content'])
                  end
                }
              end
            end
          }
        end
   
        if (json['agent_topics'] && json['agent_topics'].any?) ||
           (json['agent_genders'] && json['agent_genders'].any?)

          xml.localDescriptions {

            # TOPICS
            if json['agent_topics']
               json['agent_topics'].each do |topic|
                 subject = topic['subjects'].first['_resolved']

                 if filled_out?([subject['terms'].first['term']])

                   xml.localDescription(:localType => "associatedSubject") {
                     create_node(xml, "term", {}, subject['terms'].first['term'])  
                     topic['dates'].each do |date|
                       if date['date_type_enum'] == 'single'
                         _build_date_single(date, xml)
                       else
                         _build_date_range(date, xml)
                       end
                     end

                     topic['notes'].each do |n|
                       create_node(xml, "descriptiveNote", {}, n['content'])
                     end
                   }
                 end

               end
            end

           # GENDERS
            if json['agent_genders']
              json['agent_genders'].each do |gender|

                if filled_out?([gender['gender_enum']])
                  xml.localDescription(:localType => "gender") {
                    create_node(xml, "term", {}, gender['gender_enum'])

                    gender['dates'].each do |date|
                      if date['date_type_enum'] == 'single'
                        _build_date_single(date, xml)
                      else
                        _build_date_range(date, xml)
                      end
                    end

                    gender['notes'].each do |n|
                      create_node(xml, "descriptiveNote", {}, n['content'])
                    end
                  }

                end
              end
            end
          } # close of xml.localDescriptions
        end # of if

        
        # NOTES      
        if json['notes']
          json['notes'].each do |n|
            if n['jsonmodel_type'] == "note_bioghist"
              note_type = :biogHist
            elsif n['jsonmodel_type'] == "note_general_context"
              note_type = :generalContext
            elsif n['jsonmodel_type'] == "note_mandate"
              note_type = :mandate
            elsif n['jsonmodel_type'] == "note_legal_status"
              note_type = :legalStatus
            elsif n['jsonmodel_type'] == "note_structure_or_genealogy"
              note_type = :structureOrGenealogy
            end

            #next unless n['publish']
            xml.send(note_type) {
              n['subnotes'].each do |sn|
                case sn['jsonmodel_type']
                when 'note_abstract'
                  xml.abstract {
                    xml.text sn['content'].join('--')
                  }
                when 'note_citation'
                  atts = Hash[ sn['xlink'].map {|x, v| ["xlink:#{x}", v] }.reject{|a| a[1].nil?} ] 
                  xml.citation(atts) {
                    xml.text sn['content'].join('--')
                  }

                when 'note_definedlist'
                  xml.list(:localType => "defined:#{sn['title']}") {
                    sn['items'].each do |item|
                      xml.item(:localType => item['label']) {
                        xml.text item['value']
                      }
                    end
                  }
                when 'note_orderedlist'
                  xml.list(:localType => "ordered:#{sn['title']}") {
                    sn['items'].each do |item|
                      xml.item(:localType => sn['enumeration']) {
                        xml.text item
                      }
                    end
                  }
                when 'note_chronology'
                  atts = sn['title'] ? {:localType => sn['title']} : {} 
                  xml.chronList(atts) {
                    sn['items'].map {|i| i['events'].map {|e| [i['event_date'], e] } }.flatten(1).each do |pair|
                      date, event = pair
                      atts = (date.nil? || date.empty?) ? {} : {:standardDate => date }
                      xml.chronItem(atts) {
                        xml.event event
                      }
                    end
                  }
                when 'note_outline'
                  xml.outline {
                    sn['levels'].each do |level|
                      _expand_level(level, xml)
                    end
                  }
                when 'note_text'
                  xml.p {
                    xml.text sn['content']
                  }
                end
              end
            }
          end
        end
      } # end of xml.description
      
      xml.relations {
        if json['agent_resources']
          json['agent_resources'].each do |ar|

            if filled_out?([ar['linked_resource']])

              if ar['linked_agent_role'] == "creator" 
                role = "creatorOf"
              elsif ar['linked_agent_role'] == "subject"
                role = "subjectOf"
              else 
                role = "other"
              end
                

              xlink_attrs = {
                "resourceRelationType" => role,
                "xlink:href" => ar['file_uri'],
                "xlink:actuate" => ar['file_version_xlink_actuate_attribute'],
                "xlink:show" => ar['file_version_xlink_show_attribute'],
                "xlink:title" => ar['xlink_title_attribute'],
                "xlink:role" => ar['xlink_role_attribute'],
                "xlink:arcrole" => ar['xlink_arcrole_attribute'],
                "lastDateTimeVerified" => ar['last_verified_date']
              }

              xml.resourceRelation(clean_attrs(xlink_attrs)) {             
                create_node(xml, "relationEntry", {}, ar['linked_resource'])  

                if ar['places'] && ar['places'].any?
                  xml.places {
                    ar['places'].each do |place|
                      subject = place['_resolved']
                      xml.place {
                        xml.placeEntry(:vocabularySource => subject['source']) {
                         xml.text subject['terms'].first['term']
                        }
                      }
                     end
                  }
                end

                ar['dates'].each do |date|
                  if date['date_type_enum'] == 'single'
                    _build_date_single(date, xml)
                  else
                    _build_date_range(date, xml)
                  end
                end
              }
            end
          end
        end

        if json['related_agents']
          json['related_agents'].each do |ra|
            resolved = ra['_resolved']
            relator = ra['relator']

            name = case resolved['jsonmodel_type']
                   when 'agent_software'
                     resolved['display_name']['software_name']
                   when 'agent_family'
                     resolved['display_name']['family_name']
                   else
                     resolved['display_name']['primary_name']
                   end

            if filled_out?([name])
              attrs = {:cpfRelationType => relator, 'xlink:type' => 'simple', 'xlink:href' => AppConfig[:public_proxy_url] + resolved['uri']}

              xml.cpfRelation(clean_attrs(attrs)) {
                xml.relationEntry name

                if ra['dates']
                  if ra['dates']['date_type_enum'] == 'single'
                    _build_date_single(ra['dates'], xml)
                  else
                    _build_date_range(ra['dates'], xml)
                  end
                end
              }
            end
          end
        end

        obj.related_records.each do |record|
          role = record[:role] + "Of"
          record = record[:record]
          atts = {:resourceRelationType => role, "xlink:type" => "simple", 'xlink:href' => "#{AppConfig[:public_proxy_url]}#{record['uri']}"}
          xml.resourceRelation(atts) {
            xml.relationEntry record['title']
          }
        end
      } # end of xml.relations

      # ALTERNATIVE SET
      if json['agent_alternate_sets'] && json['agent_alternate_sets'].any?
        xml.alternativeSet {
          json['agent_alternate_sets'].each do |aas|
            xlink_attrs = {
              "xlink:href" => aas['file_uri'],
              "xlink:actuate" => aas['file_version_xlink_actuate_attribute'],
              "xlink:show" => aas['file_version_xlink_show_attribute'],
              "xlink:title" => aas['xlink_title_attribute'],
              "xlink:role" => aas['xlink_role_attribute'],
              "xlink:arcrole" => aas['xlink_arcrole_attribute'],
              "lastDateTimeVerified" => aas['last_verified_date']
            }

            if filled_out?([aas['set_component'], aas['descriptive_note']])
              xml.setComponent(clean_attrs(xlink_attrs)) {
                create_node(xml, "componentEntry", {}, aas['set_component'])
                create_node(xml, "descriptiveNote", {}, aas['descriptive_note'])
              }
            end
          end
        } # end of xml.alternativeSet
      end

    } # end of xml.cpfDescription
  end


  def _expand_level(level, xml)
    xml.level {
      level['items'].each do |item|
        if item.is_a?(String)
          xml.item item
        else
          _expand_level(item, xml)
        end
      end
    }
  end


  def _build_date_single(date, xml)
    attrs = {:standardDate => date['structured_date_single']['date_standardized'], :localType => date['date_label']}

    create_node(xml, "date", attrs, date['structured_date_single']['date_expression'])
  end

  def _build_date_range(date, xml)
    xml.dateRange(:localType => date['date_label']) {
      begin_attrs = {:standardDate => date['structured_date_range']['begin_date_standardized']}
      end_attrs = {:standardDate => date['structured_date_range']['end_date_standardized']}

      create_node(xml, "fromDate", begin_attrs, date['structured_date_range']['begin_date_expression'])

      create_node(xml, "toDate", end_attrs, date['structured_date_range']['end_date_expression'])
    }
  end

  def _build_name_entry(name, xml, json, obj)
    attrs = {"xml:lang" => name['language'], "scriptCode" => name['script'], "transliteration" => name['romanization_enum']}
    xml.nameEntry(clean_attrs(attrs)) {

      obj.name_part_fields.each do |field, localType|
        localType = localType.nil? ? field : localType
        next unless name[field]

        part_attrs = {:localType => localType}
        create_node(xml, "part", part_attrs, name[field])
      end

      xml.useDates {
        name['use_dates'].each do |date|
            if date['date_type_enum'] == 'single'
              _build_date_single(date, xml)
            else
              _build_date_range(date, xml)
            end
        end
      }

      if name['authorized']
        xml.authorizedForm name['source'] unless name['source'] && name['source'].empty?
      else
        xml.alternativeForm name['source'] unless name['source'] && name['source'].empty?
      end
    }
  end
end
