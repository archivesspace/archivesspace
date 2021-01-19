module MarcXMLAuthAgentBaseMap

  # import_events determines whether maintenance events are imported
  # lcnaf_import sets source = 'naf' for names
  def BASE_RECORD_MAP(import_events = false, lcnaf_import = false)
    {
      # AGENT PERSON
      "//datafield[@tag='100' and (@ind1='1' or @ind1='0')]" => {
        :obj => :agent_person,
        :map => agent_person_base(import_events, lcnaf_import)
      },
      # AGENT CORPORATE ENTITY
      "//datafield[@tag='110' or @tag='111']" => {
        :obj => :agent_corporate_entity,
        :map => agent_corporate_entity_base(import_events, lcnaf_import)
      },
      # AGENT FAMILY
      "//datafield[@tag='100' and @ind1='3']" => {
        :obj => :agent_family,
        :map => agent_family_base(import_events, lcnaf_import)
      }
    }
  end

  def agent_person_base(import_events, lcnaf_import)
    {
      "self::datafield" => agent_person_name_with_parallel_map(:name_person, :names, lcnaf_import),
      "//record/datafield[@tag='046']" => agent_person_dates_of_existence_map,
      "//record/datafield[@tag='372']/subfield[@code='a']" => agent_topic_map,
      "//record/datafield[@tag='375']/subfield[@code='a']" => agent_gender_map,
    }.merge(shared_subrecord_map(import_events))
  end

  def agent_corporate_entity_base(import_events, lcnaf_import)
    {
      "self::datafield" => agent_corporate_entity_name_with_parallel_map(:name_corporate_entity, :names, lcnaf_import),
      "//record/datafield[@tag='046']" => agent_corporate_entity_dates_of_existence_map,
      "//record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map,
    }.merge(shared_subrecord_map(import_events))
  end

  def agent_family_base(import_events, lcnaf_import)
    {
      "self::datafield" => agent_family_name_with_parallel_map(:name_family, :names, lcnaf_import),
      "//record/datafield[@tag='046']" => agent_family_dates_of_existence_map,
      "//record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map,
    }.merge(shared_subrecord_map(import_events))
  end

  def shared_subrecord_map(import_events)
    h = {
      "//record/leader" => agent_record_control_map,
      "//record/controlfield[@tag='001']" => agent_record_identifiers_map,
      "//record/datafield[@tag='040']/subfield[@code='e']" => convention_declaration_map,
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

    if import_events
      h.merge!({
        "//record/controlfield[@tag='005']" => maintenance_history_map,
      })
    end

    return h
  end

  def agent_person_name_with_parallel_map(obj, rel, lcnaf_import)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_person_name_components_map.merge({
        "//datafield[@tag='400' and (@ind1='1' or @ind1='0')]" => agent_person_name_map(:parallel_name_person, :parallel_names, lcnaf_import)
      }),
      :defaults => {
        :source => lcnaf_import ? 'naf' : 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_person_name_map(obj, rel, lcnaf_import)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_person_name_components_map,
      :defaults => {
        :source => lcnaf_import ? 'naf' : 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_corporate_entity_name_with_parallel_map(obj, rel, lcnaf_import)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_corporate_entity_name_components_map.merge({
        "//datafield[@tag='410' or @tag='411']" => agent_corporate_entity_name_map(:parallel_name_corporate_entity, :parallel_names, lcnaf_import)
      }),
      :defaults => {
        :source => lcnaf_import ? 'naf' : 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_corporate_entity_name_map(obj, rel, lcnaf_import)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_corporate_entity_name_components_map,
      :defaults => {
        :source => lcnaf_import ? 'naf' : 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_family_name_with_parallel_map(obj, rel, lcnaf_import)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_family_name_components_map.merge({
        "//datafield[@tag='400' and @ind1='3']" => agent_family_name_map(:parallel_name_family, :parallel_names, lcnaf_import)
      }),
      :defaults => {
        :source => lcnaf_import ? 'naf' : 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct',
      }
    }
  end

  def agent_family_name_map(obj, rel, lcnaf_import)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_family_name_components_map,
      :defaults => {
        :source => lcnaf_import ? 'naf' : 'local',
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
       "descendant::subfield[@code='b']" => Proc.new {|name, node|
          val = node.inner_text
          name[:subordinate_name_1] = val
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

  def agent_record_control_map
  {
    :obj => :agent_record_control,
    :rel => :agent_record_controls,
    :map => {
      "self::leader" => Proc.new{|arc, node|
        leader_text = node.inner_text

        case leader_text[5]
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

        arc['maintenance_status'] = status
      },
      "//record/controlfield[@tag='003']" => Proc.new{|arc, node|
        org = node.inner_text
        arc['maintenance_agency'] = org
      },

      # looks something like:
      # <marcxml:controlfield tag="008">890119nnfacannaab           |a aaa      </marcxml:controlfield>
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

        case tag8_content[8]
        when 'b'
          lang = "eng"
        when 'e'
          lang = "eng"
        when 'f'
          lang = "fre"
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
        arc['language'] = lang
        arc['government_agency_type'] = gov_agency
        arc['reference_evaluation'] = ref_eval
        arc['name_type'] = name_type
        arc['level_of_detail'] = lod
        arc['modified_record'] = mod_record
        arc['cataloging_source'] = catalog_source
      },
      "//record/datafield[@tag='040']/subfield[@code='a']" => Proc.new{|arc, node|
        val = node.inner_text

        arc['maintenance_agency'] = val
      },
     "//record/datafield[@tag='040']/subfield[@code='b']" => Proc.new{|arc, node|
        val = node.inner_text

        arc['language'] = val
      },
     "//record/datafield[@tag='040']/subfield[@code='d']" => Proc.new{|arc, node|
        val = node.inner_text

        arc['maintenance_agency'] = val
      }
    }
  }
  end

  def agent_record_identifiers_map
  {
    :obj => :agent_record_identifier,
    :rel => :agent_record_identifiers,
    :map => {
      "self::controlfield" => Proc.new {|ari, node|
        val = node.inner_text
        ari['record_identifier'] = val
      },
      "//record/datafield[@tag=010]/subfield[@code='a']" => Proc.new {|ari, node|
        val = node.inner_text
        ari['record_identifier'] = val
      },
      "//record/datafield[@tag=016]/subfield[@code='a']" => Proc.new {|ari, node|
        val = node.inner_text
        ari['record_identifier'] = val
        ari['primary_identifier'] = true

        if node.parent.attr("ind1") == "7"
          ari['identifier_type'] == "local"
        else
          ari['identifier_type'] == "lac"
        end
      },
      "//record/datafield[@tag=016]/subfield[@code='2']" => Proc.new {|ari, node|
        val = node.inner_text
        ari['source'] = val
        ari['primary_identifier'] = true

        if node.parent.attr("ind1") == "7"
          ari['identifier_type'] == "local"
        else
          ari['identifier_type'] == "lac"
        end
      },
      "//record/datafield[@tag=024]/subfield[@code='a']" => Proc.new {|ari, node|
        val = node.inner_text
        ari['record_identifier'] = val
        ari['primary_identifier'] = true

        if node.parent.attr("ind1") == "7"
          ari['identifier_type'] == "local"
        end
      },
      "//record/datafield[@tag=024]/subfield[@code='2']" => Proc.new {|ari, node|
        val = node.inner_text
        ari['source'] = val
        ari['primary_identifier'] = true

        if node.parent.attr("ind1") == "7"
          ari['identifier_type'] == "local"
        end
      },
      "//record/datafield[@tag=035]/subfield[@code='a']" => Proc.new {|ari, node|
        val = node.inner_text
        ari['record_identifier'] = val
        ari['primary_identifier'] = true

        if node.parent.attr("ind1") == "7"
          ari['identifier_type'] = "local"
        end
      },
      "//record/datafield[@tag=035]/subfield[@code='2']" => Proc.new {|ari, node|
        val = node.inner_text
        ari['source'] = val
        ari['primary_identifier'] = true

        if node.parent.attr("ind1") == "7"
          ari['identifier_type'] = "local"
        end
      },
    },
    :defaults => {
      :source => "local"
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

  def agent_person_dates_of_existence_map
  {
    :obj => :structured_date_label,
    :rel => :dates_of_existence,
    :map => {
      "self::datafield" => Proc.new {|sdl, node|
        label = "existence"
        type = "range"

        begin_node = node.search("./subfield[@code='f']")
        end_node = node.search("./subfield[@code='g']")

        begin_exp = begin_node.inner_text if begin_node
        end_exp = end_node.inner_text if end_node

        sdr = ASpaceImport::JSONModel(:structured_date_range).new({
          :begin_date_expression => begin_exp,
          :end_date_expression => end_exp,
        })

        sdl[:date_label] = label
        sdl[:date_type_structured] = type
        sdl[:structured_date_range] = sdr
      }
    }
  }
  end

  def agent_corporate_entity_dates_of_existence_map
  {
    :obj => :structured_date_label,
    :rel => :dates_of_existence,
    :map => {
      "self::datafield" => Proc.new {|sdl, node|
        label = "existence"
        type = "range"

        begin_node = node.search("./subfield[@code='s']")
        end_node = node.search("./subfield[@code='t']")

        begin_exp = begin_node.inner_text if begin_node
        end_exp = end_node.inner_text if end_node

        sdr = ASpaceImport::JSONModel(:structured_date_range).new({
          :begin_date_expression => begin_exp,
          :end_date_expression => end_exp,
        })

        sdl[:date_label] = label
        sdl[:date_type_structured] = type
        sdl[:structured_date_range] = sdr
      }
    }
  }
  end

  def agent_family_dates_of_existence_map
  {
    :obj => :structured_date_label,
    :rel => :dates_of_existence,
    :map => {
      "self::datafield" => Proc.new {|sdl, node|
        label = "existence"
        type = "range"

        begin_node = node.search("./subfield[@code='s']")
        end_node = node.search("./subfield[@code='t']")

        begin_exp = begin_node.inner_text if begin_node
        end_exp = end_node.inner_text if end_node

        sdr = ASpaceImport::JSONModel(:structured_date_range).new({
          :begin_date_expression => begin_exp,
          :end_date_expression => end_exp,
        })

        sdl[:date_label] = label
        sdl[:date_type_structured] = type
        sdl[:structured_date_range] = sdr
      }
    }
  }
  end

  def date_range_map(rel = :dates, begin_subfield = 's', end_subfield = 't')
  {
    :obj => :structured_date_label,
    :rel => rel,
    :map => {
      "parent::datafield" => Proc.new {|sdl, node|

        begin_node = node.search("subfield[@code='#{begin_subfield}']")
        end_node = node.search("subfield[@code='#{end_subfield}']")

        begin_exp = begin_node.inner_text if begin_node
        end_exp = end_node.inner_text if end_node

        sdr = ASpaceImport::JSONModel(:structured_date_range).new({
          :begin_date_expression => begin_exp,
          :end_date_expression => end_exp,
        })

        sdl[:date_label] = 'existence'
        sdl[:date_type_structured] = 'range'
        sdl[:structured_date_range] = sdr
      }
    }
  }
  end

  def place_of_birth_map
  {
    :obj => :agent_place,
    :rel => :agent_places,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('geographic', 'a'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
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
      "self::subfield" => subject_map(subject_terms_map('geographic', 'b'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
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
      "self::subfield" => subject_map(subject_terms_map('geographic', 'c'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
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
      "self::subfield" => subject_map(subject_terms_map('geographic', 'e'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
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
      "self::subfield" => subject_map(subject_terms_map('geographic', 'f'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
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
      "self::subfield" => subject_map(subject_terms_map('occupation', 'a'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
    }
  }
  end

  def agent_topic_map
  {
    :obj => :agent_topic,
    :rel => :agent_topics,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('topical', 'a'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
    }
  }
  end

  def agent_function_map
  {
    :obj => :agent_function,
    :rel => :agent_functions,
    :map => {
      "self::subfield" => subject_map(subject_terms_map('function', 'a'),
                                      sets_subject_source),
      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
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

      "parent::datafield/subfield[@code='s' or @code='t']" => date_range_map
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

        sn = ASpaceImport::JSONModel(:note_text).new({
          :content => val
        })
        note['subnotes'] << sn
      },
      "descendant::subfield[@code='b']" => Proc.new {|note, node|
        val = node.inner_text

        sn = ASpaceImport::JSONModel(:note_abstract).new({
          :content => [val]
        })
        note['subnotes'] << sn
      },
    }
  }
  end

  def subject_terms_map(term_type, subfield)
    Proc.new {|node|
      [{:term_type => term_type,
       :term => node.at_xpath("subfield[@code='#{subfield}']").inner_text,
       :vocabulary => '/vocabularies/1'}]
    }
  end

  def sets_subject_source
    Proc.new{|node|
      !node.at_xpath("subfield[@code='2']").nil? ? node.at_xpath("subfield[@code='2']").inner_text : 'Source not specified'
    }
  end

  # usually, rel will be :subjects, but in some cases it will be :places
  def subject_map(terms, getsrc, rel = :subjects)
    {
      :obj => :subject,
      :rel => rel,
      :map => {
        "parent::datafield" => Proc.new{|subject, node|
          subject.publish = true
          subject.terms = terms.call(node)
          subject.source = getsrc.call(node)
          subject.vocabulary = '/vocabularies/1'
          if !node.at_xpath("subfield[@code='0']").nil?
            subject.authority_id = node.at_xpath("subfield[@code='0']").inner_text
          end
        }
      },
      :defaults => {
        :source => "Source not specified"
      }
    }
  end

end
