module MarcXMLAuthAgentBaseMap
  # import_events determines whether maintenance events are imported
  # import_subjects determines whether subjects are imported
  def BASE_RECORD_MAP(opts = {:import_events => false, :import_subjects => false})
    import_events   = opts[:import_events]
    import_subjects = opts[:import_subjects]

    {
      # AGENT PERSON
      "//datafield[@tag='100' and (@ind1='1' or @ind1='0')]" => {
        :obj => :agent_person,
        :map => agent_person_base(import_events, import_subjects)
      },
      # AGENT CORPORATE ENTITY
      "//datafield[@tag='110' or @tag='111']" => {
        :obj => :agent_corporate_entity,
        :map => agent_corporate_entity_base(import_events, import_subjects)
      },
      # AGENT FAMILY
      "//datafield[@tag='100' and @ind1='3']" => {
        :obj => :agent_family,
        :map => agent_family_base(import_events, import_subjects)
      }
    }
  end

  def agent_person_base(import_events, import_subjects)
    p = {
      'self::datafield' => agent_person_name_map(:name_person, :names),
      "parent::record/datafield[@tag='400' and (@ind1='1' or @ind1='0')]" => agent_person_name_map(:name_person, :names),
      "parent::record/datafield[@tag='375']/subfield[@code='a']" => agent_gender_map
    }.merge(shared_subrecord_map(import_events, import_subjects))

    if import_subjects
      p.merge!({
        "parent::record/datafield[@tag='372']/subfield[@code='a']" => agent_topic_map
      })
    end

    p
  end

  def agent_corporate_entity_base(import_events, import_subjects)
    c = {
      'self::datafield' => agent_corporate_entity_name_map(:name_corporate_entity, :names),
      "parent::record/datafield[@tag='410' or @tag='411']" => agent_corporate_entity_name_map(:name_corporate_entity, :names)
    }.merge(shared_subrecord_map(import_events, import_subjects))

    if import_subjects
      c.merge!({
        "parent::record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map
      })
    end

    c
  end

  def agent_family_base(import_events, import_subjects)
    f = {
      'self::datafield' => agent_family_name_map(:name_family, :names),
      "parent::record/datafield[@tag='400' and @ind1='3']" => agent_family_name_map(:name_family, :names)
    }.merge(shared_subrecord_map(import_events, import_subjects))

    if import_subjects
      f.merge!({
        "parent::record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map
      })
    end

    f
  end

  def shared_subrecord_map(import_events, import_subjects)
    h = {
      'parent::record/leader' => agent_record_control_map,
      "parent::record/controlfield[@tag='001'][not(following-sibling::controlfield[@tag='003']/text()='DLC' and following-sibling::datafield[@tag='010'])]" => agent_record_identifiers_base_map("//record/controlfield[@tag='001']"),
      "parent::record/datafield[@tag='010']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='010']/subfield[@code='a']"),
      "parent::record/datafield[@tag='016']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='016']/subfield[@code='a']"),
      "parent::record/datafield[@tag='024']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='024']/subfield[@code='a' or @code='0' or @code='1'][1]"),
      "parent::record/datafield[@tag='035']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='035']/subfield[@code='a']"),
      "parent::record/datafield[@tag='040']/subfield[@code='e']" => convention_declaration_map,
      "parent::record/datafield[@tag='046']" => dates_map,

      "parent::record/datafield[@tag='377']" => used_language_map,
      "parent::record/datafield[@tag='500'][not(@ind1='3')]" => related_agent_map('person'),
      "parent::record/datafield[@tag='500'][@ind1='3']" => related_agent_map('family'),
      "parent::record/datafield[@tag='510']" => related_agent_map('corporate_entity'),
      "parent::record/datafield[@tag='511']" => related_agent_map('corporate_entity'),
      "parent::record/datafield[@tag='670']" => agent_sources_map,
      "parent::record/datafield[@tag='678']" => bioghist_note_map,
      "parent::record/datafield[@tag='040']/subfield[@code='d']" => {
        :obj => :agent_other_agency_codes,
        :rel => :agent_other_agency_codes,
        :map => {
          "self::subfield" => proc { |aoac, node|
            aoac['maintenance_agency'] = node.inner_text
          }
        }
      },
      "parent::record" => proc { |record, node|
        # apply the more complicated inter-leaf logic
        record['agent_other_agency_codes'].reject! { |subrecord|
          subrecord['maintenance_agency'] == record['agent_record_controls'][0]['maintenance_agency']
        }
      }
    }

    if import_events
      h.merge!({
        "parent::record/controlfield[@tag='005']" => maintenance_history_map
      })
    end

    if import_subjects
      h.merge!({
        "parent::record/datafield[@tag='374']/subfield[@code='a']" => agent_occupation_map,
        "parent::record/datafield[@tag='370']/subfield[@code='a']" => place_of_birth_map,
        "parent::record/datafield[@tag='370']/subfield[@code='b']" => place_of_death_map,
        "parent::record/datafield[@tag='370']/subfield[@code='c']" => associated_country_map,
        "parent::record/datafield[@tag='370']/subfield[@code='e']" => place_of_residence_map,
        "parent::record/datafield[@tag='370']/subfield[@code='f']" => other_associated_place_map
      })
    end

    h
  end

  def agent_person_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_person_name_components_map,
      :defaults => {
        :name_order => 'direct'
      }
    }
  end

  def agent_corporate_entity_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_corporate_entity_name_components_map,
      :defaults => {
        :name_order => 'direct'
      }
    }
  end

  def agent_family_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_family_name_components_map,
      :defaults => {
        :name_order => 'direct'
      }
    }
  end

  def agent_person_name_components_map
    {
       "descendant::subfield[@code='a']" => proc { |name, node|
         val = node.inner_text

         if node.parent.attr('ind1') == '0'
           delim = ' '
           name[:name_order] = 'direct'
         elsif node.parent.attr('ind1') == '1'
           delim = ', '
           name[:name_order] = 'inverted'
         end

         name[:authorized] = node.parent.attr('tag') == '100'

         nom_parts = val.split(delim, 2)

         name[:primary_name] = nom_parts[0].chomp(',')
         name[:rest_of_name] = nom_parts[1].chomp(',') if nom_parts[1]
       },
       "descendant::subfield[@code='b']" => trim('number'),
       "descendant::subfield[@code='c']" => trim('title'),
       "descendant::subfield[@code='d']" => trim('dates'),
       "descendant::subfield[@code='g']" => proc { |name, node|
         val = node.inner_text
         name[:qualifier] = val
       },
       "descendant::subfield[@code='q']" => trim('fuller_form', ',', ['(', ')']),
       "parent::record/datafield[@tag='378']/subfield[@code='q']" => proc { |name, node|
         if name[:authorized]
           val = node.inner_text

           name[:fuller_form] = val if name[:fuller_form].nil?
         end
       }
    }
  end

  def agent_corporate_entity_name_components_map
    {
      "self::datafield[@ind1='1']" => proc { |name, _node|
        name[:jurisdiction] = true
      },
      "descendant::subfield[@code='a']" => proc { |name, node|
                                             val = node.inner_text

                                             if node.parent.attr('tag') == '110' || node.parent.attr('tag') == '410' || node.parent.attr('tag') == '510'
                                               name[:conference_meeting] = false
                                             elsif node.parent.attr('tag') == '111' || node.parent.attr('tag') == '411' || node.parent.attr('tag') == '511'
                                               name[:conference_meeting] = true
                                             end

                                             name[:authorized] = if node.parent.attr('tag') == '110' || node.parent.attr('tag') == '111'
                                                                   true
                                                                 else
                                                                   false
                                                                 end

                                             name[:primary_name] = val.chomp('.')
                                           },
      "self::datafield[@tag='110' or @tag='410' or @tag='510']" => proc { |name, node|
                                                       subordinate_names = []
                                                       sf_bs = node.search("./subfield[@code='b']")
                                                       sf_bs.each do |b|
                                                         subordinate_names << b.inner_text
                                                       end
                                                       name[:subordinate_name_1] = subordinate_names.shift
                                                       name[:subordinate_name_2] = subordinate_names.join('. ')
                                                     },
      "descendant::subfield[@code='c']" => proc { |name, node|
                                             val = node.inner_text
                                             name[:location] = val
                                           },
      "descendant::subfield[@code='d']" => proc { |name, node|
                                             val = node.inner_text
                                             name[:dates] = val
                                           },
      "descendant::subfield[@code='n']" => trim('number', '.', ['(', ')', ':']),
      "descendant::subfield[@code='g']" => proc { |name, node|
                                             val = node.inner_text
                                             name[:qualifier] = val
                                           },
      "descendant::subfield[@code='e']" => proc { |name, node|
                                             val = node.inner_text

                                             name[:subordinate_name_1] = val if node.parent.attr('tag') == '111' || node.parent.attr('tag') == '411' || node.parent.attr('tag') == '511'
                                           },
      "descendant::subfield[@code='q']" => proc { |name, node|
                                             val = node.inner_text

                                             name[:subordinate_name_2] = val if node.parent.attr('tag') == '411' || node.parent.attr('tag') == '511'

                                             name[:qualifier] = "Name of meeting following jurisdiction name entry element: " + val if node.parent.attr('tag') == '111'
                                           }
    }
  end

  def agent_family_name_components_map
    {
      "descendant::subfield[@code='a']" => proc { |name, node|
                                             name[:authorized] = node.parent.attr('tag') == '100'

                                             val = node.inner_text

                                             name[:family_name] = val
                                           },
      "descendant::subfield[@code='b']" => proc { |name, node|
                                             val = node.inner_text
                                             name[:qualifier] = val
                                           },
      "descendant::subfield[@code='c']" => trim('qualifier', ',', ['(', ')']),
      "descendant::subfield[@code='d']" => trim('dates', ':'),
      "descendant::subfield[@code='g']" => proc { |name, node|
                                             val = node.inner_text
                                             name[:qualifier] = val
                                           }
    }
  end

  def set_maintenance_status(pos_5)
    case pos_5
    when 'n'
      status = 'new'
    when 'a'
      status = 'upgraded'
    when 'c'
      status = 'revised_corrected'
    when 'd'
      status = 'deleted'
    when 'o'
      status = 'cancelled_obsolete'
    when 's'
      status = 'deleted_split'
    when 'x'
      status = 'deleted_replaced'
    end

    status
  end

  def set_record_language()
    -> obj, node {
      obj['language'] = nil
      lang_040 = node.at_xpath("subfield[@code='b']")&.inner_text
      obj['language'] = lang_040 if lang_040
    }
  end

  def agent_record_control_map
    {
      :obj => :agent_record_control,
      :rel => :agent_record_controls,
      :map => {
        'self::leader' => proc { |arc, node|
          leader_text = node.inner_text
          arc['maintenance_status'] = set_maintenance_status(leader_text[5])
        },
        "parent::record/datafield[@tag='040']/subfield[@code='a']" => proc { |arc, node|
          arc['maintenance_agency'] = node.inner_text
        },
        "parent::record/controlfield[@tag='003']" => proc { |arc, node|
          unless arc['maintenance_agency']
            arc['maintenance_agency'] = node.inner_text
          end
        },
        "parent::record/datafield[@tag='040']" => set_record_language(),
        "parent::record/controlfield[@tag='008']" => proc { |arc, node|
          tag8_content = node.inner_text

          unless arc['language']
            arc['language'] = case String(node&.inner_text)[8]
                              when 'b'
                                'mul'
                              when 'e'
                                'eng'
                              when 'f'
                                'fre'
                              end
          end

          case tag8_content[7]
          when 'a'
            romanization = 'int_std'
          when 'b'
            romanization = 'nat_std'
          when 'c'
            romanization = 'nl_assoc_std'
          when 'd'
            romanization = 'nl_bib_agency_std'
          when 'e'
            romanization = 'local_std'
          when 'f'
            romanization = 'unknown_std'
          when 'g'
            romanization = 'conv_rom_cat_agency'
          when 'n'
            romanization = 'not_applicable'
          when '|'
            romanization = ''
          end

          case tag8_content[28]
          when '#'
            gov_agency = 'ngo'
          when 'a'
            gov_agency = 'sac'
          when 'c'
            gov_agency = 'multilocal'
          when 'f'
            gov_agency = 'fed'
          when 'I'
            gov_agency = 'int_gov'
          when 'l'
            gov_agency = 'local'
          when 'm'
            gov_agency = 'multistate'
          when 'o'
            gov_agency = 'undetermined'
          when 's'
            gov_agency = 'provincial'
          when 'u'
            gov_agency = 'unknown'
          when 'z'
            gov_agency = 'other'
          when '|'
            gov_agency = 'unknown'
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
        }
      }
    }
  end

  def set_primary_identifier(node)
    # Kind of hacky, but we're not bringing in 001s in situations where the
    # 003=DLC and there is an 010 since these would presumably be near duplicates.
    # Therefore, we don't want to falsely set an unimported 001 as the primary id.
    node003 = node.at_xpath("ancestor::record/controlfield[@tag='003']")&.inner_text
    node010 = node.at_xpath("ancestor::record/datafield[@tag='010']")&.attr('tag')
    node001 = node.at_xpath("ancestor::record/controlfield[@tag='001']")&.attr('tag') unless node003 == 'DLC' && node010

    this_node = node.attr('tag') || node.parent.attr('tag')
    ids = []
    ids << node001 if node001
    ids << node010
    ids << node.at_xpath("ancestor::record/datafield[@tag='016']")&.attr('tag')
    ids << node.at_xpath("ancestor::record/datafield[@tag='024']")&.attr('tag')
    ids << node.at_xpath("ancestor::record/datafield[@tag='035']")&.attr('tag')
    first_node = ids.compact.first.to_s

    this_node == first_node
  end

  def agent_record_identifiers_base_map(xpath)
    {
      :obj => :agent_record_identifier,
      :rel => :agent_record_identifiers,
      :map => {
        xpath => proc { |ari, node|
          val = node.inner_text
          ari['record_identifier'] = val
          ari['primary_identifier'] = set_primary_identifier(node)

          if node.parent.attr('tag') == '010'
            ari['source'] = 'naf'
            ari['identifier_type'] = 'loc'
          elsif node.parent.attr('tag') == '016'
            ari['source'] = 'lac' if node.parent.attr('ind1') == '#'
          end

          if node.parent.attr('tag') == '035' && val.start_with?('(DLC)')
            ari['source'] = 'naf'
            ari['identifier_type'] = 'loc'
          end

          if node.parent.attr('ind1') == '7'
            sf_2 = (node.parent).at_xpath("subfield[@code='2']")
            ari['source'] = sf_2.inner_text if sf_2
            ari['identifier_type'] = 'local'
          end
        }
      },
      :defaults => {
      :source => 'local',
      :primary_identifier => false
    }
  }
  end

  def maintenance_history_map
    {
      :obj => :agent_maintenance_history,
      :rel => :agent_maintenance_histories,
      :map => {
        'self::controlfield' => proc { |amh, node|
          tag5_content = node.inner_text

          amh['event_date'] = tag5_content[0..7]
          amh['maintenance_event_type'] = 'created'
          amh['maintenance_agent_type'] = 'machine'
        },
        "parent::record/controlfield[@tag='008']" => proc { |amh, node|
          tag8_content = node.inner_text

          # The MARC Authority format was not developed until the 1970s, and the
          #   first 2 digits of the authority 008 are specifically defined as a
          #   computer-generated date representing the creation of the MARC
          #   record. Therefore, “19” should never be the prefix if the decade
          #   is represented by a number less than 7
          century = tag8_content[0].to_i < 7 ? '20' : '19'
          amh['event_date'] = century + tag8_content[0..5]
          amh['maintenance_event_type'] = 'created'
          amh['maintenance_agent_type'] = 'machine'
        },
        "parent::record/datafield[@tag='040']/subfield[@code='d']" => proc { |amh, node|
          val = node.inner_text
          val.empty? ? 'Missing in File' : val
          amh['agent'] = val
        }
      },
      :defaults => {
        :agent => 'Missing in File'
      }
    }
  end

  def convention_declaration_map
    {
      :obj => :agent_conventions_declaration,
      :rel => :agent_conventions_declarations,
      :map => {
        'self::subfield' => proc { |acd, node|
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
      next if date_node.nil?

      begin
        date = DateTime.parse(date_node)
        date = date.strftime('%F')
      # Invalid date will just get an expression
      rescue StandardError
        date = nil
      end
    end
    date
  end

  def expression_date_for(node, subfields)
    date = nil
    subfields.each do |sc|
      date_node = node.at_xpath("subfield[@code='#{sc}']")
      date = date_node.inner_text unless date_node.nil?
    end
    date
  end

  def dates_map(rel = :dates_of_existence)
    {
      :obj => :structured_date_label,
      :rel => rel,
      :map => {
        'self::datafield' => proc { |sdl, node|
          date_begin = structured_date_for(node, ['f', 'q', 's'])
          date_end = structured_date_for(node, ['g', 'r', 't'])
          date_begin_expression = expression_date_for(node, ['f', 'q', 's'])
          date_end_expression = expression_date_for(node, ['g', 'r', 't'])

          date_type = if ((date_begin && date_end) && (date_end.to_i > date_begin.to_i)) || (date_begin_expression && date_end_expression)
                        'range'
                      else
                        'single'
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
        'self::subfield' => subject_map(subject_terms_map('geographic', 'a')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      },
      :defaults => {
        :place_role => 'place_of_birth'
      }
    }
  end

  def place_of_death_map
    {
      :obj => :agent_place,
      :rel => :agent_places,
      :map => {
        'self::subfield' => subject_map(subject_terms_map('geographic', 'b')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      },
      :defaults => {
        :place_role => 'place_of_death'
      }
    }
  end

  def associated_country_map
    {
      :obj => :agent_place,
      :rel => :agent_places,
      :map => {
        'self::subfield' => subject_map(subject_terms_map('geographic', 'c')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      },
      :defaults => {
        :place_role => 'assoc_country'
      }
    }
  end

  def place_of_residence_map
    {
      :obj => :agent_place,
      :rel => :agent_places,
      :map => {
        'self::subfield' => subject_map(subject_terms_map('geographic', 'e')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      },
      :defaults => {
        :place_role => 'residence'
      }
    }
  end

  def other_associated_place_map
    {
      :obj => :agent_place,
      :rel => :agent_places,
      :map => {
        'self::subfield' => subject_map(subject_terms_map('geographic', 'f')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      },
      :defaults => {
        :place_role => 'other_assoc'
      }
    }
  end

  def agent_occupation_map
    {
      :obj => :agent_occupation,
      :rel => :agent_occupations,
      :map => {
        'self::subfield' => subject_map(subject_terms_map('occupation', 'a')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      }
    }
  end

  def agent_topic_map
    {
      :obj => :agent_topic,
      :rel => :agent_topics,
      :map => {
        'self::subfield' => subject_map(subject_terms_map('topical', 'a')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      }
    }
  end

  def agent_function_map
    {
      :obj => :agent_function,
      :rel => :agent_functions,
      :map => {
        'self::subfield' => subject_map(subject_terms_map('function', 'a')),
        "parent::datafield[descendant::subfield[@code='s' or @code='t']]" => dates_map(:dates)
      }
    }
  end

  def agent_gender_map
    {
      :obj => :agent_gender,
      :rel => :agent_genders,
      :map => {
        'self::subfield' => proc { |gender, node|
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
        "descendant::subfield[@code='l']" => proc { |lang, node|
          val = node.inner_text
          lang['language'] = val
        },
        "descendant::subfield[@code='a']" => proc { |lang, node|
          val = node.inner_text
          lang['language'] = val if val
        }
      }
    }
  end

  def agent_sources_map
    {
      :obj => :agent_sources,
      :rel => :agent_sources,
      :map => {
        "descendant::subfield[@code='b']" => proc { |as, node|
          val = node.inner_text
          as['descriptive_note'] = val
        },
        "descendant::subfield[@code='a']" => proc { |as, node|
          val = node.inner_text
          as['source_entry'] = val
        },
        "descendant::subfield[@code='u']" => proc { |as, node|
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
        'self::datafield' => proc { |note, node|
          if node.attr('ind1') == '0'
            note['label'] = 'Biographical note'
          elsif node.attr('ind1') == '1'
            note['label'] = 'Administrative history'
          end
        },
        "descendant::subfield[@code='a']" => proc { |note, node|
          val = node.inner_text

          sn = ASpaceImport::JSONModel(:note_abstract).new({
            :content => [val]
          })
          note['subnotes'] << sn
        },
        "descendant::subfield[@code='b']" => proc { |note, node|
          val = node.inner_text

          sn = ASpaceImport::JSONModel(:note_text).new({
            :content => val
          })
          note['subnotes'] << sn
        }
      }
    }
  end

  def related_agent_map(type)
    {
      :obj => :"agent_#{type}",
      :rel => proc { |agent, rel_agent|
        agent[:related_agents] << {
          :relator => rel_agent['_relator'] || 'is_associative_with',
          :jsonmodel_type => rel_agent['_jsonmodel_type'] || 'agent_relationship_associative',
          :specific_relator => rel_agent['_specific_relator'],
          :relationship_uri => rel_agent['_relationship_uri'],
          :description => rel_agent['_description'],
          :ref => rel_agent.uri
        }
      },
      :map => {
        "descendant::subfield[@code='w']" => proc { |agent, node|
          relator, specific_relator, relationship_type = find_relationship(node, type)
          agent['_relator'] = relator
          agent['_specific_relator'] = specific_relator
          agent['_jsonmodel_type'] = relationship_type
        },
        "descendant::subfield[@code='4']" => proc { |agent, node|
          agent['_relationship_uri'] = node.inner_text
        },
        "descendant::subfield[@code='i']" => proc { |agent, node|
          agent['_description'] = node.inner_text
        },
        'self::datafield' => {
          :obj => :"name_#{type}",
          :rel => :names,
          :map => send("agent_#{type}_name_components_map"),
          :defaults => {
            :name_order => 'direct',
            :source => 'ingest'
          }
        }
      }
    }
  end

  def find_relationship(node, type)
    case node.inner_text[0]
    when 'a'
      relator = 'is_earlier_form_of'
      relationship_type = 'agent_relationship_earlierlater'
    when 'b'
      relator = 'is_later_form_of'
      relationship_type = 'agent_relationship_earlierlater'
    when 'd'
      relator = 'is_identified_with'
      specific_relator = 'Acronym'
      relationship_type = 'agent_relationship_identity'
    when 'f'
      relator = 'is_associative_with'
      specific_relator = 'Musical composition'
      relationship_type = 'agent_relationship_associative'
    when 'g'
      relator = 'is_associative_with'
      specific_relator = 'Broader term'
      relationship_type = 'agent_relationship_associative'
    when 'h'
      relator = 'is_associative_with'
      specific_relator = 'Narrower term'
      relationship_type = 'agent_relationship_associative'
    when 't'
      # Have to ensure both the base record and related record are corp entities
      if type == 'corporate_entity' && !node.search("parent::record/datafield[@tag='110']").empty?
        relator = 'is_superior_of'
        specific_relator = 'Immediate parent body'
        relationship_type = 'agent_relationship_subordinatesuperior'
      end
    else
      relator = 'is_associative_with'
      relationship_type = 'agent_relationship_associative'
    end

    [relator, specific_relator, relationship_type]
  end

  def subject_terms_map(term_type, _subfield)
    proc { |node|
      [{ :term_type => term_type,
         :term => node.inner_text,
         :vocabulary => '/vocabularies/1' }]
    }
  end

  # Sometimes we need to create more than one subject from a MARC field with a
  # subfield 0, but the subject creation will fail if you try to create
  # subjects with duplicate authority ids. Only create an authority id for the
  # first subject created, and leaves authority id blank
  def set_auth_id(node)
    siblings = node.search("./preceding-sibling::*[not(@code='0' or @code='2')]")

    auth_id = node.parent.at_xpath("subfield[@code='0']").inner_text if siblings.empty?

    auth_id
  end

  # usually, rel will be :subjects, but in some cases it will be :places
  def subject_map(terms, rel = :subjects)
    {
      :obj => :subject,
      :rel => rel,
      :map => {
        'self::subfield' => proc { |subject, node|
          subject.publish = true
          subject.terms = terms.call(node)
          subject.source = node.parent.at_xpath("subfield[@code='2']").inner_text unless node.parent.at_xpath("subfield[@code='2']").nil?
          subject.vocabulary = '/vocabularies/1'
          subject.authority_id = set_auth_id(node) unless node.parent.at_xpath("subfield[@code='0']").nil?
        }
      },
      :defaults => {
        :source => 'Source not specified'
      }
    }
  end

  def trim(property, trailing_char = ',', remove_chars = [])
    -> name, node {
      val = node.inner_text
      remove_chars.each { |char| val = val.gsub(/#{Regexp.escape(char)}/, '') }
      name[property] = val.chomp(trailing_char)
    }
  end
end
