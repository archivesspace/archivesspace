module MarcXMLAuthAgentBaseMap

  # import_events determines whether maintenance events are imported
  def BASE_RECORD_MAP(import_events = false)
    {
      # AGENT PERSON
      "//datafield[@tag='100' and (@ind1='1' or @ind1='0')]" => {
        :obj => :agent_person,
        :map => agent_person_base(import_events)
      },
      # AGENT CORPORATE ENTITY
      "//datafield[@tag='110' or @tag='111']" => {
        :obj => :agent_corporate_entity,
        :map => agent_corporate_entity_base(import_events)
      },
      # AGENT FAMILY
      "//datafield[@tag='100' and @ind1='3']" => {
        :obj => :agent_family,
        :map => agent_family_base(import_events)
      }
    }
  end

  def agent_person_base(import_events)
    {
      "self::datafield" => agent_person_name_map(:name_person, :names),
      "//datafield[@tag='400' and (@ind1='1' or @ind1='0')]" => agent_person_name_map(:name_person, :names),
      "//record/datafield[@tag='372']/subfield[@code='a']" => agent_topic_map,
      "//record/datafield[@tag='375']/subfield[@code='a']" => agent_gender_map,
    }.merge(shared_subrecord_map(import_events))
  end

  def agent_corporate_entity_base(import_events)
    {
      "self::datafield" => agent_corporate_entity_name_map(:name_corporate_entity, :names),
      "//datafield[@tag='410' or @tag='411']" => agent_corporate_entity_name_map(:name_corporate_entity, :names),
      "//record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map,
    }.merge(shared_subrecord_map(import_events))
  end

  def agent_family_base(import_events)
    {
      "self::datafield" => agent_family_name_map(:name_family, :names),
      "//datafield[@tag='400' and @ind1='3']" => agent_family_name_map(:name_family, :names),
      "//record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map,
    }.merge(shared_subrecord_map(import_events))
  end

  def shared_subrecord_map(import_events)
    h = {
      "//record/leader" => agent_record_control_map,
      "//record/controlfield[@tag='001']" => agent_record_identifiers_base_map("//record/controlfield[@tag='001']"),
      "//record/datafield[@tag='010']" => agent_record_identifiers_base_map("//record/datafield[@tag='010']/subfield[@code='a']"),
      "//record/datafield[@tag='016']" => agent_record_identifiers_base_map("//record/datafield[@tag='016']/subfield[@code='a']"),
      "//record/datafield[@tag='024']" => agent_record_identifiers_base_map("//record/datafield[@tag='024']/subfield[@code='a']"),
      "//record/datafield[@tag='035']" => agent_record_identifiers_base_map("//record/datafield[@tag='035']/subfield[@code='a']"),
      "//record/datafield[@tag='040']/subfield[@code='e']" => convention_declaration_map,
      "//record/datafield[@tag='046']" => dates_map,
      "//record/datafield[@tag='370']/subfield[@code='a']" => place_of_birth_map,
      "//record/datafield[@tag='370']/subfield[@code='b']" => place_of_death_map,
      "//record/datafield[@tag='370']/subfield[@code='c']" => associated_country_map,
      "//record/datafield[@tag='370']/subfield[@code='e']" => place_of_residence_map,
      "//record/datafield[@tag='370']/subfield[@code='f']" => other_associated_place_map,
      "//record/datafield[@tag='374']/subfield[@code='a']" => agent_occupation_map,
      "//record/datafield[@tag='377']" => used_language_map,
      "//record/datafield[@tag='670']" => agent_sources_map,
      "//record/datafield[@tag='678']" => bioghist_note_map,
    }
    
    # We only want to import other_agency codes for maintenance agencies not already in record_info
    if @ma_040_a
      h.merge!({
        "//record/datafield[@tag='040']/subfield[@code='d' and text()!='#{@ma_040_a}']" => other_agency_code_map,
      })
    end

    if import_events
      h.merge!({
        "//record/controlfield[@tag='005']" => maintenance_history_map,
      })
    end

    return h
  end

  def agent_person_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_person_name_components_map,
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_corporate_entity_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_corporate_entity_name_components_map,
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_family_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_family_name_components_map,
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_person_name_components_map
    {
       "descendant::subfield[@code='a']" => Proc.new {|name, node|
          val = node.inner_text

          if node.parent.attr("ind1") == "0"
            delim = " "
            name[:name_order] = 'direct'
          elsif node.parent.attr("ind1") == "1"
            delim = ","
            name[:name_order] = 'inverted'
          end

          if node.parent.attr("tag") == "100"
            name[:authorized] = true
          else
            name[:authorized] = false
          end

          if val =~ /#{delim}/
            nom_parts = val.split(delim, 2)
          else
            nom_parts = val.split(delim, 2)
          end

          name[:primary_name] = nom_parts[0]
          name[:rest_of_name] = nom_parts[1]
       },
       "descendant::subfield[@code='b']" => Proc.new {|name, node|
          val = node.inner_text
          name[:number] = val
       },
       "descendant::subfield[@code='c']" => Proc.new {|name, node|
          val = node.inner_text
          name[:title] = val
       },
       "descendant::subfield[@code='d']" => Proc.new {|name, node|
          val = node.inner_text
          name[:dates] = val
       },
       "descendant::subfield[@code='g']" => Proc.new {|name, node|
          val = node.inner_text
          name[:qualifier] = val
       },
       "descendant::subfield[@code='q']" => Proc.new {|name, node|
          val = node.inner_text
          name[:fuller_form] = val
       },
       "//record/datafield[@tag='378']/subfield[@code='q']" => Proc.new {|name, node|
          val = node.inner_text

          if name[:fuller_form].nil?
            name[:fuller_form] = val
          end
       },
    }
  end

  def agent_corporate_entity_name_components_map
    {
      "self::datafield[@ind1='1']" => Proc.new {|name, node|
         name[:jurisdiction] = true
      },
      "descendant::subfield[@code='a']" => Proc.new {|name, node|
          val = node.inner_text

          if node.parent.attr("tag") == "110" || node.parent.attr("tag") == "410"
            name[:conference_meeting] = false
          elsif node.parent.attr("tag") == "111" || node.parent.attr("tag") == "411"
            name[:conference_meeting] = true
          end

          if node.parent.attr("tag") == "110" || node.parent.attr("tag") == "111"
            name[:authorized] = true
          else
            name[:authorized] = false
          end

          name[:primary_name] = val
       },
       "self::datafield[@tag='110' or @tag='410']" => Proc.new {|name, node|
          subordinate_names = []
          sf_bs = node.search("./subfield[@code='b']")
          sf_bs.each do |b|
            subordinate_names << b.inner_text
          end
          name[:subordinate_name_1] = subordinate_names.shift
          name[:subordinate_name_2] = subordinate_names.join('. ')
       },
       "descendant::subfield[@code='c']" => Proc.new {|name, node|
          val = node.inner_text
          name[:location] = val
       },
       "descendant::subfield[@code='d']" => Proc.new {|name, node|
          val = node.inner_text
          name[:dates] = val
       },
       "descendant::subfield[@code='n']" => Proc.new {|name, node|
          val = node.inner_text
          name[:number] = val
       },
       "descendant::subfield[@code='g']" => Proc.new {|name, node|
          val = node.inner_text
          name[:qualifier] = val
       },
       "descendant::subfield[@code='e']" => Proc.new {|name, node|
          val = node.inner_text

          if node.parent.attr("tag") == "111" || node.parent.attr("tag") == "411"
            name[:subordinate_name_1] = val
          end
       },
       "descendant::subfield[@code='q']" => Proc.new {|name, node|
          val = node.inner_text

          if node.parent.attr("tag") == "111" || node.parent.attr("tag") == "411"
            name[:subordinate_name_2] = val
          end
       },
    }
  end

  def agent_family_name_components_map
    {
      "descendant::subfield[@code='a']" => Proc.new {|name, node|
          if node.parent.attr("tag") == "100"
            name[:authorized] = true
          else
            name[:authorized] = false
          end

          val = node.inner_text

          name[:family_name] = val
       },
       "descendant::subfield[@code='b']" => Proc.new {|name, node|
          val = node.inner_text
          name[:qualifier] = val
       },
       "descendant::subfield[@code='c']" => Proc.new {|name, node|
          val = node.inner_text
          name[:qualifier] = val
       },
        "descendant::subfield[@code='d']" => Proc.new {|name, node|
          val = node.inner_text
          name[:dates] = val
       },
       "descendant::subfield[@code='g']" => Proc.new {|name, node|
          val = node.inner_text
          name[:qualifier] = val
       },
    }
  end
  
  def set_maintenance_status(pos_5)
    case pos_5
    when 'n'
      status = "new"
    when 'a'
      status = "upgraded"
    when 'c'
      status = "revised_corrected"
    when 'd'
      status = "deleted"
    when 'o'
      status = "cancelled_obsolete"
    when 's'
      status = "deleted_split"
    when 'x'
      status = "deleted_replaced"
    end
    
    status
  end
  
  def other_agency_code_map
    {
      :obj => :agent_other_agency_codes,
      :rel => :agent_other_agency_codes,
      :map => {
        "self::subfield" => Proc.new {|oac, node|
          oac['maintenance_agency'] = node.inner_text
        }
      }
    }
  end
  
  def set_maintenance_agency(node)
    # We're gonna save this for later because it matters for other_agency_code_map
    @ma_040_a = node.search("//record/datafield[@tag='040']/subfield[@code='a']").inner_text
    
    if !@ma_040_a.empty?
      agency = @ma_040_a
    else
      agency = node.search("//record/controlfield[@tag='003']").inner_text
    end
    
    agency
  end
  
  def set_record_language(node)
    lang_040 = node.search("//record/datafield[@tag='040']/subfield[@code='b']").inner_text
    if !lang_040.empty?
      lang = lang_040
    else
      tag8_content = node.search("//record/controlfield[@tag='008']").inner_text
      
      case tag8_content[8]
      when 'b'
       lang = 'mul'
      when 'e'
       lang = 'eng'
      when 'f'
       lang = 'fre'
      end
    end
    
    lang
  end

  def agent_record_control_map
  {
    :obj => :agent_record_control,
    :rel => :agent_record_controls,
    :map => {
      "self::leader" => Proc.new{|arc, node|
         leader_text = node.inner_text
      
         arc['maintenance_status'] = set_maintenance_status(leader_text[5])
       },
      "//record" => Proc.new{|arc, node|
        arc['maintenance_agency'] = set_maintenance_agency(node)
        arc['language'] = set_record_language(node)
      },
      "//record/controlfield[@tag='008']" => Proc.new{|arc, node|
        tag8_content = node.inner_text

        case tag8_content[7]
        when 'a'
          romanization = "int_std"
        when 'b'
          romanization = "nat_std"
        when 'c'
          romanization = "nl_assoc_std"
        when 'd'
          romanization = "nl_bib_agency_std"
        when 'e'
          romanization = "local_std"
        when 'f'
          romanization = "unknown_std"
        when 'g'
          romanization = "conv_rom_cat_agency"
        when 'n'
          romanization = "not_applicable"
        when '|'
          romanization = ""
        end
     
        case tag8_content[28]
        when '#'
          gov_agency = "ngo"
        when 'a'
          gov_agency = "sac"
        when 'c'
          gov_agency = "multilocal"
        when 'f'
          gov_agency = "fed"
        when 'I'
          gov_agency = "int_gov"
        when 'l'
          gov_agency = "local"
        when 'm'
          gov_agency = "multistate"
        when 'o'
          gov_agency = "undetermined"
        when 's'
          gov_agency = "provincial"
        when 'u'
          gov_agency = "unknown"
        when 'z'
          gov_agency = "other"
        when '|'
          gov_agency = "unknown"
        end

        case tag8_content[29]
        when 'a'
          ref_eval = 'tr_consistent'
        when 'b'
          ref_eval = 'tr_inconsistent'
        when 'n'
          ref_eval = 'not_applicable'
        when '|'
          ref_eval = 'natc'
        end

        case tag8_content[32]
        when 'a'
          name_type = 'differentiated'
        when 'b'
          name_type = 'undifferentiated'
        when 'n'
          name_type = 'not_applicable'
        when '|'
          name_type = 'natc'
        end

        case tag8_content[33]
        when 'a'
          lod = 'fully_established'
        when 'b'
          lod = 'memorandum'
        when 'c'
          lod = 'provisional'
        when 'd'
          lod = 'preliminary'
        when 'n'
          lod = 'not_applicable'
        when '|'
          lod = 'natc'
        end

        case tag8_content[38]
        when '#'
          mod_record = 'not_modified'
        when 's'
          mod_record = 'shortened'
        when 'x'
          mod_record = 'missing_characters'
        when '|'
          mod_record = 'natc'
        end

        case tag8_content[39]
        when '#'
          catalog_source = 'nat_bib_agency'
        when 'c'
          catalog_source = 'ccp'
        when 'd'
          catalog_source = 'other'
        when 'u'
          catalog_source = 'unknown'
        when '|'
          catalog_source = 'natc'
        end
     
        arc['romanization'] = romanization
        arc['government_agency_type'] = gov_agency
        arc['reference_evaluation'] = ref_eval
        arc['name_type'] = name_type
        arc['level_of_detail'] = lod
        arc['modified_record'] = mod_record
        arc['cataloging_source'] = catalog_source
      },
    }
  }
  end
  
  def set_primary_identifier(node)
    this_node = node.attr('tag') || node.parent.attr('tag')
    ids = []
    ids << node.search("//record/controlfield[@tag='001']").attr('tag')
    ids << node.search("//record/datafield[@tag='010']").attr('tag')
    ids << node.search("//record/datafield[@tag='016']").attr('tag')
    ids << node.search("//record/datafield[@tag='024']").attr('tag')
    ids << node.search("//record/datafield[@tag='035']").attr('tag')
    first_node = ids.compact.first.to_s
    
    if this_node == first_node
      true
    else
      false
    end 
    
  end 
  
  def agent_record_identifiers_base_map(xpath)
    {
      :obj => :agent_record_identifier,
      :rel => :agent_record_identifiers,
      :map => {
        xpath => Proc.new {|ari, node|
          val = node.inner_text
          ari['record_identifier'] = val
          ari['primary_identifier'] = set_primary_identifier(node)
          
          if node.parent.attr('tag') == '010'
            ari['source'] = 'naf'
            ari['identifier_type'] = 'loc'
          elsif node.parent.attr('tag') == '016'
            if node.parent.attr('ind1') == "#"
              ari['source'] = 'lac'
            end
          end
            
          if node.parent.attr('ind1') == '7'
            sf_2 = (node.parent).at_xpath("subfield[@code='2']")
            ari['source'] = sf_2.inner_text if sf_2
            ari['identifier_type'] = 'local'
          end
          
        }
      },
    :defaults => {
      :source => "local",
      :primary_identifier => false
    }  
  }
  end

  def maintenance_history_map
  {
    :obj => :agent_maintenance_history,
    :rel => :agent_maintenance_histories,
    :map => {
      "self::controlfield" => Proc.new {|amh, node|
        tag5_content = node.inner_text

        amh['event_date'] = tag5_content[0..7]
        amh['maintenance_event_type'] = "created"
        amh['maintenance_agent_type'] = "machine"
      },
      "//record/controlfield[@tag='008']" => Proc.new{|amh, node|
        tag8_content = node.inner_text

        amh['event_date'] = "19" + tag8_content[0..5]
        amh['maintenance_event_type'] = "created"
        amh['maintenance_agent_type'] = "machine"
      },
      "//record/datafield[@tag='040']/subfield[@code='d']" => Proc.new{|amh, node|
        val = node.inner_text
        val.empty? ? "Missing in File" : val
        amh['agent'] = val
      }
    },
    :defaults => {
      :agent => "Missing in File"
    }
  }
  end

  def convention_declaration_map
  {
    :obj => :agent_conventions_declaration,
    :rel => :agent_conventions_declarations,
    :map => {
      "self::subfield" => Proc.new {|acd, node|
        val = node.inner_text
        acd['name_rule'] = val
      }
    }
  }
  end

  def structured_date_for(node, subfields)
    date = nil
    subfields.each do |sc|
      date_node = node.at_xpath("subfield[@code='#{sc}']")
      unless date_node.nil?
        begin
          date = DateTime.parse(date_node)
          date = date.strftime('%F')
        # Invalid date will just get an expression
        rescue
          date = nil
        end
      end
    end
    date
  end

  def expression_date_for(node, subfields)
    date = nil
    subfields.each do |sc|
      date_node = node.at_xpath("subfield[@code='#{sc}']")
      unless date_node.nil?
        date = date_node.inner_text
      end
    end
    date
  end

  def dates_map(rel = :dates_of_existence)
  {
    :obj => :structured_date_label,
    :rel => rel,
    :map => {
      "self::datafield" => Proc.new {|sdl, node|

        date_begin = structured_date_for(node, ['f', 'q', 's'])
        date_end = structured_date_for(node, ['g', 'r', 't'])
        date_begin_expression = expression_date_for(node, ['f', 'q', 's'])
        date_end_expression = expression_date_for(node, ['g', 'r', 't'])
        
        if ((date_begin and date_end) and (date_end.to_i > date_begin.to_i)) || (date_begin_expression and date_end_expression)
          date_type = 'range'
        else
          date_type = 'single'
        end

        if date_type == 'single'
          sd = ASpaceImport::JSONModel(:structured_date_single).new(
            {
              :date_standardized => date_begin || date_end,
              :date_expression => date_begin_expression || date_end_expression,
              :date_role => date_begin ? 'begin' : 'end'
          }
        )
        elsif date_type == 'range'
          sd = ASpaceImport::JSONModel(:structured_date_range).new(
            {
              :begin_date_standardized => date_begin,
              :end_date_standardized => date_end,
              :begin_date_expression => date_begin_expression,
              :end_date_expression => date_end_expression
            }
          )
        end

        sdl[:date_label] = 'existence'
        sdl[:date_type_structured] = date_type
        sdl[:"structured_date_#{date_type}"] = sd
      }
    }
  }
  end

  def place_of_birth_map
  {
    :obj => :agent_place,
    :rel => :agent_places,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('geographic', 'a')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    },
    :defaults => {
      :place_role => "place_of_birth"
    }
  }
  end

  def place_of_death_map
  {
    :obj => :agent_place,
    :rel => :agent_places,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('geographic', 'b')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    },
    :defaults => {
      :place_role => "place_of_death"
    }
  }
  end

  def associated_country_map
  {
    :obj => :agent_place,
    :rel => :agent_places,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('geographic', 'c')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    },
    :defaults => {
      :place_role => "assoc_country"
    }
  }
  end

  def place_of_residence_map
  {
    :obj => :agent_place,
    :rel => :agent_places,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('geographic', 'e')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    },
    :defaults => {
      :place_role => "residence"
    }
  }
  end

  def other_associated_place_map
  {
    :obj => :agent_place,
    :rel => :agent_places,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('geographic', 'f')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    },
    :defaults => {
      :place_role => "other_assoc"
    }
  }
  end

  def agent_occupation_map
  {
    :obj => :agent_occupation,
    :rel => :agent_occupations,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('occupation', 'a')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    }
  }
  end

  def agent_topic_map
  {
    :obj => :agent_topic,
    :rel => :agent_topics,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('topical', 'a')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    }
  }
  end

  def agent_function_map
  {
    :obj => :agent_function,
    :rel => :agent_functions,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('function', 'a')),
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    }
  }
  end

  def agent_gender_map
  {
    :obj => :agent_gender,
    :rel => :agent_genders,
    :map => {
      "self::subfield" => Proc.new {|gender, node|
        val = node.inner_text
        gender['gender'] = val
      },
      "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
    }
  }
  end

  def used_language_map
  {
    :obj => :used_language,
    :rel => :used_languages,
    :map => {
      "descendant::subfield[@code='l']" => Proc.new {|lang, node|
        val = node.inner_text
        lang['language'] = val
      },
      "descendant::subfield[@code='a']" => Proc.new {|lang, node|
        val = node.inner_text
        lang['language'] = val
      }
    }
  }
  end

  def agent_sources_map
  {
    :obj => :agent_sources,
    :rel => :agent_sources,
    :map => {
      "descendant::subfield[@code='b']" => Proc.new {|as, node|
        val = node.inner_text
        as['descriptive_note'] = val[0..254]
      },
      "descendant::subfield[@code='a']" => Proc.new {|as, node|
        val = node.inner_text
        as['source_entry'] = val
      },
      "descendant::subfield[@code='u']" => Proc.new {|as, node|
        val = node.inner_text
        as['file_uri'] = val
      }
    }
  }
  end


  def bioghist_note_map
  {
    :obj => :note_bioghist,
    :rel => :notes,
    :map => {
      "self::datafield" => Proc.new {|note, node|
        if node.attr("ind1") == "0"
          note['label'] = "Biographical note"
        elsif node.attr("ind1") == "1"
          note['label'] = "Administrative history"
        end
      },
      "descendant::subfield[@code='a']" => Proc.new {|note, node|
        val = node.inner_text

        sn = ASpaceImport::JSONModel(:note_abstract).new({
          :content => [val]
        })
        note['subnotes'] << sn
      },
      "descendant::subfield[@code='b']" => Proc.new {|note, node|
        val = node.inner_text

        sn = ASpaceImport::JSONModel(:note_text).new({
          :content => val
        })
        note['subnotes'] << sn
      },
    }
  }
  end

  def subject_terms_map(term_type, subfield)
    Proc.new {|node|
      [{:term_type => term_type,
       :term => node.inner_text,
       :vocabulary => '/vocabularies/1'}]
    }
  end
  
  # Sometimes we need to create more than one subject from a MARC field with a
  # subfield 0, but the subject creation will fail if you try to create
  # subjects with duplicate authority ids. Only create an authority id for the
  # first subject created, and leaves authority id blank
  def set_auth_id(node)
    siblings = node.search("./preceding-sibling::*[not(@code='0' or @code='2')]")
    
    if siblings.empty?
      auth_id = node.parent.at_xpath("subfield[@code='0']").inner_text
    end
    
    auth_id
  end 

  # usually, rel will be :subjects, but in some cases it will be :places
  def subject_map(terms, rel = :subjects)
    {
      :obj => :subject,
      :rel => rel,
      :map => {
        "self::subfield" => Proc.new{|subject, node|
          subject.publish = true
          subject.terms = terms.call(node)
          if !node.parent.at_xpath("subfield[@code='2']").nil?
            subject.source = node.parent.at_xpath("subfield[@code='2']").inner_text
          end
          subject.vocabulary = '/vocabularies/1'
          if !node.parent.at_xpath("subfield[@code='0']").nil?
            subject.authority_id = set_auth_id(node)
          end
        }
      },
      :defaults => {
        :source => "Source not specified"
      }
    }
  end

end
