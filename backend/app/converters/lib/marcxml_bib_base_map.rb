
module MarcXMLBibBaseMap

  AUTH_SUBJECT_SOURCE = {
    'a'=>"lcsh",
    'b'=>"LC subject headings for children's literature",
    'c'=>"Medical Subject Headings",
    'd'=>"National Agricultural Library subject authority file",
    'k'=>"Canadian Subject Headings",
    'n'=>"Not applicable",
    'r'=>"Art and Architecture Thesaurus",
    's'=>"Sears List of Subject Headings",
    'v'=>"R\u00E9pertoire de vedettes-matic\u00E8re",
    'z'=>"Other"
  }

  BIB_SUBJECT_SOURCE = {
    '0'=>"lcsh",
    '1'=>"LC subject headings for children's literature",
    '2'=>"Medical Subject Headings",
    '3'=>"National Agricultural Library subject authority file",
    '4'=>"Source not specified",
    '5'=>"Canadian Subject Headings",
    '6'=>"R\u00E9pertoire de vedettes-matic\u00E8re"
  }

  def record_properties(type_of_record = nil, source = nil, rules = nil)
    @properties ||= { type: :bibliographic, source: nil , rules: nil}
    if type_of_record
      @properties[:type] = type_of_record == 'z' ? :authority : :bibliographic
    end
    if @properties[:type] == :authority
      @properties[:source] = source if source
      @properties[:rules]  = rules  if rules
    end
    @properties
  end

  alias_method :set_record_properties, :record_properties

  def subject_template(getterms, getsrc, variant_tag = nil)
    {
      :obj => :subject,
      :rel => :subjects,
      :map => {
        "//controlfield[@tag='001']" => sets_authority_properties(true, false, :subject),
        "self::datafield" => -> subject, node {
          subject.publish = true
          subject.terms = getterms.call(node)
          subject.source = getsrc.call(node)
          subject.vocabulary = '/vocabularies/1'
        },
        "//datafield[@tag='680']" => -> subject, node {
          subject.scope_note = concatenate_subfields(['a', 'i'], node, ' ', true)
        },
        # update source if this is lcgft: https://www.loc.gov/catdir/cpso/genre_form_faq.pdf
        "//datafield[@tag='040']" => -> subject, node {
          if record_properties[:type] == :authority
            if subject.source == 'Other' and node.at_xpath("subfield[@code='f']").inner_text == 'lcgft'
              subject.source = 'lcgft'
            end
          end
        },
        # skip handling variant (4XX) headings until subject / term data model
        # supports authorized / unauthorized and multiple headings per subject
        # these just pollute the database as is
        # "//datafield[@tag='#{variant_tag || '999'}']" => -> subject, node {
        #   # TODO
        # }
      }
    }
  end


  def make_term(term_type, term)
    if !term.empty? && !term_type.nil?
      {:term_type => term_type, :term => term, :vocabulary => '/vocabularies/1'}
    end
  end


  def sets_subject_source
    -> node {
      if record_properties[:type] == :authority
        AUTH_SUBJECT_SOURCE[ record_properties[:source] ] || 'Source not specified'
      else
        BIB_SUBJECT_SOURCE[node.attr('ind2')] || ( !node.at_xpath("subfield[@code='2']").nil? ? node.at_xpath("subfield[@code='2']").inner_text : 'Source not specified' )
      end
    }
  end


  def agent_template
    {
      :rel => -> resource, agent {
        agent.publish = true
        resource[:linked_agents] << {
          # stashed value for the role
          :role => agent['_role'] || 'subject',
          :terms => agent['_terms'] || [],
          :relator => agent['_relator'],
          :ref => agent.uri,
          :is_primary => agent['_is_primary']
        }
      },
      :map => {
        "subfield[@code='e']" => -> agent, node {
          agent['_relator'] = node.inner_text
        },
        "subfield[@code='4']" => -> agent, node {
          agent['_relator'] = node.inner_text unless agent['_relator']
        },
        "self::datafield" => {
          :defaults => {
            :name_order => 'direct',
            :source => 'ingest'
          }
        },
        "//datafield[@tag='046']" => {
          :obj => :date,
          :rel => :dates_of_existence,
          :map => {
            "self::datafield" => Proc.new {|date, node|
              date.expression = concatenate_subfields(['f', 'q', 's', 'g', 'r', 't'], node, '-', true)
              date.begin      = dates_of_existence_date_for(node, ['f', 'q', 's'])
              end_date        = dates_of_existence_date_for(node, ['g', 'r', 't'])
              if (date.begin and end_date) and (end_date.to_i > date.begin.to_i)
                date.end = end_date
              end
              date.date_type = date.end ? 'range' : 'single'
            }
          },
          :defaults => {
            :label => 'existence',
            :date_type => 'single',
          }
        },
        "//datafield[@tag='678']" => {
          :obj => :note_bioghist,
          :rel => :notes,
          :map => {
            "self::datafield" => Proc.new {|note, node|
              note['subnotes'] << {
                'jsonmodel_type' => 'note_text',
                'content' => concatenate_subfields(['a', 'b', 'u'], node, ' ', true),
                'publish' => true,
              }
            }
          },
          :defaults => {
            :label => 'Biographical / Historical',
            :publish => true,
          }
        },
      }
    }
  end


  def name_person_map(primary = false, authorized = false)
    {
      "//controlfield[@tag='001']" => sets_authority_properties(primary, authorized),
      "@ind1" => sets_name_order_from_ind1,
      "subfield[@code='a']" => sets_primary_and_rest_of_name,
      "subfield[@code='b']" => trim('number'),
      "subfield[@code='c']" => trim('title'),

      "subfield[@code='d']" => trim('dates'),
      "subfield[@code='f']" => adds_prefixed_qualifier('Date of work'),
      "subfield[@code='g']" => adds_prefixed_qualifier('Miscellaneous information'),
      "subfield[@code='h']" => adds_prefixed_qualifier('Medium'),
      "subfield[@code='j']" => adds_prefixed_qualifier('Attribution qualifier', ' -- '),
      "subfield[@code='k']" => adds_prefixed_qualifier('Form subheading'),
      "subfield[@code='l']" => adds_prefixed_qualifier('Language of a work'),
      "subfield[@code='m']" => adds_prefixed_qualifier('Medium of performance for music'),
      "subfield[@code='n']" => adds_prefixed_qualifier('Number of part/section of a work'),
      "subfield[@code='o']" => adds_prefixed_qualifier('Arranged statement for music'),
      "subfield[@code='p']" => adds_prefixed_qualifier('Name of a part/section of a work'),
      "subfield[@code='r']" => adds_prefixed_qualifier('Key for music'),
      "subfield[@code='s']" => adds_prefixed_qualifier('Version'),
      "subfield[@code='t']" => adds_prefixed_qualifier('Title of work'),
      "subfield[@code='u']" => adds_prefixed_qualifier('Affiliation'),
      "subfield[@code='q']" => trim('fuller_form', ',', ['(', ')']),
    }
  end


  def person_template
    mix(agent_template, {
      :obj => :agent_person,
      :map => {
        # NAMES (PERSON)
        "self::datafield" => {
          :obj => :name_person,
          :rel => :names,
          :map => name_person_map(true, true)
        },
        "//datafield[@tag='400'][@ind1='0' or @ind1='1']" => {
          :obj => :name_person,
          :rel => :names,
          :map => name_person_map,
          :defaults => {
            :name_order => 'direct',
            :source => 'ingest'
          }
        }
      }
    })
  end


  def name_family_map(primary = false, authorized = false)
    {
      "//controlfield[@tag='001']" => sets_authority_properties(primary, authorized),
      "subfield[@code='a']" => trim('family_name', ',', ['(', ')']),
      "subfield[@code='c']" => trim('qualifier', ',', ['(', ')']),
      "subfield[@code='d']" => trim('dates', ':'),
      "subfield[@code='f']" => adds_prefixed_qualifier('Date of work'),
      "subfield[@code='g']" => adds_prefixed_qualifier('Miscellaneous information'),
      "subfield[@code='q']" => adds_prefixed_qualifier('', ''),
      "subfield[@code='r']" => adds_prefixed_qualifier('Key for music'),
      "subfield[@code='s']" => adds_prefixed_qualifier('Version'),
      "subfield[@code='t']" => adds_prefixed_qualifier('Title of work'),
      "subfield[@code='u']" => adds_prefixed_qualifier('Affiliation'),
    }
  end


  def family_template
    mix(agent_template, {
      :obj => :agent_family,
      :map => {
        # NAMES (FAMILY)
        "self::datafield" => {
          :obj => :name_family,
          :rel => :names,
          :map => name_family_map(true, true),
        },
        "//datafield[@tag='400'][@ind1='3']" => {
          :obj => :name_family,
          :rel => :names,
          :map => name_family_map,
          :defaults => {
            :name_order => 'direct',
            :source => 'ingest'
          }
        }
      }
    })
  end


  def name_corp_map(primary = false, authorized = false)
    {
      "//controlfield[@tag='001']" => sets_authority_properties(primary, authorized),
      "subfield[@code='a']" => trim('primary_name', '.'),
      "subfield[@code='b'][1]" => trim('subordinate_name_1', '.'),
      "subfield[@code='b'][2]" => trim('subordinate_name_2', '.'),
      "subfield[@code='b'][3]" => appends_subordinate_name_2,
      "subfield[@code='b'][4]" => appends_subordinate_name_2,
      "subfield[@code='c']" => trim('location', '.'),
      "subfield[@code='d']" => adds_prefixed_qualifier('Date of meeting or treaty signing'),
      "subfield[@code='f']" => adds_prefixed_qualifier('Date of work'),
      "subfield[@code='n']" => trim('number', '.', ['(', ')', ':']),
      "subfield[@code='g']" => adds_prefixed_qualifier('Miscellaneous information'),
      "subfield[@code='h']" => adds_prefixed_qualifier('Medium'),
      "subfield[@code='k']" => adds_prefixed_qualifier('Form subheading'),
      "subfield[@code='l']" => adds_prefixed_qualifier('Language of a work'),
      "subfield[@code='o']" => adds_prefixed_qualifier('Arranged statement for music'),
      "subfield[@code='p']" => adds_prefixed_qualifier('Name of a part/section of a work'),
      "subfield[@code='r']" => adds_prefixed_qualifier('Key for music'),
      "subfield[@code='s']" => adds_prefixed_qualifier('Version'),
      "subfield[@code='t']" => adds_prefixed_qualifier('Title of work'),
      "subfield[@code='u']" => adds_prefixed_qualifier('Affiliation'),
      "@ind1" => sets_jurisdiction_from_ind1,
    }
  end


  def corp_template
    mix(agent_template, {
      :obj => :agent_corporate_entity,
      :map => {
        # NAMES (CORPORATE)
        "self::datafield" => {
          :obj => :name_corporate_entity,
          :rel => :names,
          :map => name_corp_map(true, true),
        },
        "//datafield[@tag='410']" => {
          :obj => :name_corporate_entity,
          :rel => :names,
          :map => name_corp_map,
          :defaults => {
            :name_order => 'direct',
            :source => 'ingest'
          }
        },
        "//datafield[@tag='411']" => {
          :obj => :name_corporate_entity,
          :rel => :names,
          :map => name_corp_map,
          :defaults => {
            :name_order => 'direct',
            :source => 'ingest'
          }
        }
      }
    })
  end


  # agents from 100 field are creators
  # this is the same map as #sources below, with the exception of adding the is_primary flag by default
  # TODO: remove source stuff from #creator and creator stuff from #source, not confident in changing this at this time
  def creators
    {
      :map => {
        "subfield[@code='d']" => :dates,
        "subfield[@code='e']" => -> agent, node {
          agent['_role'] = case
                           when ['Auctioneer (auc)',
                                 'Bookseller (bsl)',
                                 'Collector (col)',
                                 'Depositor (dpt)',
                                 'Donor (dnr)',
                                 'Former owner (fmo)',
                                 'Funder (fnd)',
                                 'Owner (own)'].include?(node.inner_text)

                             'source'
                           else
                             'creator'
                           end
        },
        "self::datafield" => {
          :map => {
            "@ind1" => sets_name_order_from_ind1,
            "subfield[@code='v']" => adds_prefixed_qualifier('Form subdivision'),
            "subfield[@code='x']" => adds_prefixed_qualifier('General subdivision'),
            "subfield[@code='y']" => adds_prefixed_qualifier('Chronological subdivision'),
            "subfield[@code='z']" => adds_prefixed_qualifier('Geographic subdivision'),
          },
          :defaults => {
            :source => 'ingest',
          }
        }
      },
      :defaults => {
        '_role' => 'creator',
        '_is_primary' => true,
      }
    }
  end

  # agents from 700 field are sources
  def sources
    {
      :map => {
        "subfield[@code='d']" => :dates,
        "subfield[@code='e']" => -> agent, node {
          agent['_role'] = case
                           when ['Auctioneer (auc)',
                                 'Bookseller (bsl)',
                                 'Collector (col)',
                                 'Depositor (dpt)',
                                 'Donor (dnr)',
                                 'Former owner (fmo)',
                                 'Funder (fnd)',
                                 'Owner (own)'].include?(node.inner_text)

                             'source'
                           else
                             'creator'
                           end
        },
        "self::datafield" => {
          :map => {
            "@ind1" => sets_name_order_from_ind1,
            "subfield[@code='v']" => adds_prefixed_qualifier('Form subdivision'),
            "subfield[@code='x']" => adds_prefixed_qualifier('General subdivision'),
            "subfield[@code='y']" => adds_prefixed_qualifier('Chronological subdivision'),
            "subfield[@code='z']" => adds_prefixed_qualifier('Geographic subdivision'),
          },
          :defaults => {
            :source => 'ingest',
          }
        }
      },
      :defaults => {
        '_role' => 'creator'
      }
    }
  end


  # agents derived from 600 fields
  def agent_as_subject
    {
      :map => {
        "subfield[@code='v']" => adds_agent_term('genre_form'),
        "subfield[@code='x']" => adds_agent_term('topical'),
        "subfield[@code='y']" => adds_agent_term('temporal'),
        "subfield[@code='z']" => adds_agent_term('geographic'),
        "self::datafield" => {
          :map => {
            "@ind1" => sets_name_order_from_ind1,
            "@ind2" => sets_name_source_from_code,
            "subfield[@code='2']" => sets_other_name_source
          }
        }
      }
    }
  end


  def corp_variation
    {
      :map => {
        "self::datafield" => {
          :map => {
            "subfield" => sets_conference_meeting,
            "subfield[@code='e'][0]" => trim('subordinate_name_1', '.'),
            "subfield[@code='e'][1]" => trim('subordinate_name_2', '.'),
            "subfield[@code='e'][2]" => appends_subordinate_name_2,
            "subfield[@code='e'][3]" => appends_subordinate_name_2,
            "subfield[@code='q']" => adds_prefixed_qualifier('Name of meeting following jurisdiction name entry element')
          },
        }
      }
    }
  end


  def bibliography_note_template(label, template=nil, *tmpl_args)
    {
      :obj => :note_bibliography,
      :rel => :notes,
      :map => {
        "self::datafield" => -> note, node {
          content = template ? subfield_template(template, node, *tmpl_args) : node.inner_text
          note.send('label=', label)
          note.content << content
        }
      }
    }
  end


  def singlepart_note(note_type, label, template=nil, *tmpl_args)
    {
      :obj => :note_singlepart,
      :rel => :notes,
      :map => {
        "self::datafield" => -> note, node {
          content = template ? subfield_template(template, node, *tmpl_args) : node.inner_text
          note.send('label=', label)
          note.type = note_type
          note.content << content
        }
      }
    }
  end


  def multipart_note(note_type, label = nil, template=nil, *tmpl_args)
    {
      :obj => :note_multipart,
      :rel => :notes,
      :map => {
        "self::datafield" => -> note, node {
          content = template ? subfield_template(template, node, *tmpl_args) : node.inner_text

          label = label.call(node) if label.is_a?(Proc)

          note.send('label=', label) if label
          note.type = note_type
          note.subnotes = [{'jsonmodel_type' => 'note_text', 'content' => content}]
        }
      }
    }
  end


  def langmaterial_note(*tmpl_args)
    {
      :obj => :note_langmaterial,
      :rel => :notes,
      :map => {
        "self::datafield" => -> note, node {
          content = template ? subfield_template(template, node, *tmpl_args) : node.inner_text
          note.label = 'Language of Material'
          note.type = 'langmaterial'
          note.content << content
        }
      }
    }
  end


  def adds_agent_term(term_type, prefix = "")
    -> agent, node {
      agent['_terms'] ||= []
      make(:term) do |term|
        term.term_type = term_type
        term.term = "#{node.inner_text}"
        term.vocabulary = '/vocabularies/1'
        agent['_terms'] << term
      end
    }
  end


  def sets_authority_properties(primary = false, authorized = false, type = :name)
    -> auth, node {
      if record_properties[:type] == :authority
        authority_id = primary ? node.inner_text : nil
        auth['authority_id'] = authority_id
        if authorized
          auth['authorized']      = true
          auth['is_display_name'] = true
        end
        if type == :name
          auth['rules']  = ['b', 'c', 'd'].include?(record_properties[:rules]) ? 'aacr' : nil
          auth['source'] = (record_properties[:source] == 'a' ? 'naf' : 'ingest')
        end
      end
    }
  end

  def sets_primary_and_rest_of_name
    -> name, node {
      val = node.inner_text
      if val.match(/\A(.+),\s*(.+)\s*\Z/)
        name['primary_name'] = $1.chomp(',')
        name['rest_of_name'] = $2.chomp(',')
      else
        name['primary_name'] = val.chomp(',')
      end
    }
  end

  def sets_jurisdiction_from_ind1
    -> name, node {
      name['jurisdiction'] = case node.value
                             when '1'
                               true
                             when '0'
                               false
                             end
    }
  end

  def sets_name_order_from_ind1
    -> name, node {
      name['name_order'] = case node.value
                           when '1'
                             'inverted'
                           when '0'
                             'direct'
                           end
    }
  end

  def sets_name_source_from_code
    -> name, node {
      src = ASpaceMappings::MARC21.get_aspace_source_code(node.value)
      name.source = src if src
    }
  end


  def sets_other_name_source
    -> name, node {
      name.source = node.inner_text unless name.source
    }
  end


  def sets_use_date_from_code_d
    -> name, node {

      date_begin, date_end = nil
      date_type = 'single'

      if node.inner_text.strip =~ /^([0-9]{4})-([0-9]{4})$/
        date_begin, date_end = node.inner_text.strip.split("-")
        date_type = "range"
      end

      make(:date) do |date|
        date.label = 'other'
        date.date_type = date_type
        date.begin = date_begin
        date.end = date_end
        date.expression = node.inner_text
        name.use_dates << date
      end
    }
  end


  def adds_prefixed_qualifier(prefix, separator = ': ')
    -> name, node {
      val = node.inner_text
      if val
        name.qualifier ||= ""
        name.qualifier += " " unless name.qualifier.empty?
        name.qualifier += prefix + separator + val + "."
      end
    }
  end


  def trim(property, trailing_char = ',', remove_chars = [])
    -> name, node {
      val = node.inner_text
      remove_chars.each { |char| val = val.gsub(/#{Regexp.escape(char)}/, '') }
      name[property] = val.chomp(trailing_char)
    }
  end


  def appends_subordinate_name_2
    -> name, node {
      name.subordinate_name_2 ||= ""
      name.subordinate_name_2 += ". " unless name.subordinate_name_2.empty?
      name.subordinate_name_2 += node.inner_text.chomp(".")
    }
  end

  def sets_conference_meeting
    -> name, node {
      name.conference_meeting = true
    }
  end

  # Create Note content strings from a template
  # E.g., "{Indicator 1 @ind1--}{$3: }{$a: }{$b: }{$c }{($x)}"
  # Sections wrapped in '{}' should only appear if the value
  # can be produced. A chain of sketcky substitutions at
  # the end attempts to keep the punctuation normal.
  def subfield_template(template, node, map=nil)
    result = template.dup
    section = /\{([^@${]*)([@$])(ind[0-9]|\S{1})([^}]*)\}/
    while result.match(section)
      if $2 == '@'
        val = node.attr("#{$3}")
      else
        val = ""
        node.xpath("subfield[@code='#{$3}']").each do |subnode|
          postpend = subnode.inner_text
          unless postpend.empty?
            val += " " unless val.empty?
            val += postpend
          end
        end
      end
      val.strip!
      val = val.empty? ? nil : val

      val = map && map.has_key?($3) && map[$3].has_key?(val) ? map[$3][val] : val

      if val
        result.sub!(section, "#{$1}#{val}#{$4}")
      else
        result.sub!(section, '')
      end
    end

    result.strip
          .gsub(/\[\]/, '')
          .gsub(/\(\)/, '')
          .gsub(/\(\s+/, '(')
          .gsub(/\s+\)/, ')')
          .gsub(/,\)/, ')')
          .gsub(/[:;,]$/, '')
          .gsub(/[:;,](\s?)\s*([()])/, '\1\2')
          .gsub(/\s+/, ' ')
          .gsub(/,\s*([^A-Za-z0-9_\s])/, '\1')
          .gsub(/[.:;]?\s*\./, '.')
          .strip
  end

  # codearray - any enumerable yielding letter / number codes
  def concatenate_subfields(codearray, node, delim=' ', subfield_order = false)
    result = ""
    if subfield_order
      result = node.children.map do |subfield|
        codearray.include?(subfield[:code]) ? subfield.inner_text : ''
      end.join(delim).squeeze(delim).strip
    else
      codearray.each do |code|
        val = node.xpath("subfield[@code='#{code}']").inner_text
        unless val.empty?
          result += delim unless result.empty?
          result += val
        end
      end
    end

    result
  end


  def dates_of_existence_date_for(node, subfields)
    date = nil
    subfields.each do |sc|
      date_node = node.at_xpath("subfield[@code='#{sc}']")
      date      = date_node.inner_text.strip.gsub(/[^\d]/, '') if date_node
      date      = (date and date.length >= 4) ? date[0..3] : nil
    end
    date
  end


  def is_fallback_resource_title
    {
      :rel => -> resource, obj {
        resource['_fallback_titles'] ||= []
        if obj.respond_to?(:subnotes)
          resource['_fallback_titles'] << obj.subnotes[0]['content']
        end
      }
    }
  end

  # this should be called 'build_base_map'
  # because the extending class calls it
  # when it is configuring itself, and the
  # result may depend on methods defined in
  # the extending class.
  def BASE_RECORD_MAP
    {
      :obj => :resource,
      :defaults => {
       :level => 'collection',
       :finding_aid_language => 'und',
       :finding_aid_script => 'Zyyy'
      },
      :map => {
        #LEADER
        "//leader" =>  -> resource, node {
          values = node.inner_text.strip
          set_record_properties values[6]

          if resource.respond_to?(:level)
            resource.level = "item" if values[7] == 'm'
          end
        },

        #CONTROLFIELD
        "//controlfield[@tag='008']" => -> resource, node {
          control = node.inner_text.strip
          set_record_properties nil, control[11], control[10]

          if control[35..37] != "   "
            make(:lang_material) do |lang|
              lang.language_and_script = {'jsonmodel_type' => 'language_and_script', 'language' => control[35..37]}

              resource.lang_materials << lang

            end
          else
            make(:lang_material) do |lang|
              lang.language_and_script = {'jsonmodel_type' => 'language_and_script', 'language' => 'und'}

              resource.lang_materials << lang

            end
          end

          if %w(i k s).include?(control[6])
            make(:date) do |date|
              date.label = 'creation'
              date.date_type = {'i' => 'inclusive',
                'k' => 'bulk',
                's' => 'single'}[control[6]]

              if control[7..10] && control[7..10].match(/^\d{4}$/)
                date.begin = control[7..10]
              elsif control[7..10]
                #somewhat hackish, but lets us cope with e.g. 19uu
                date.expression = control[7..10]
              end

              if control[11..14] && control[11..14].match(/^\d{4}$/)
                date.end = control[11..14]
              end

              resource.dates << date
            end
          end
        },

        # ID_0, ID_1, ID_2, ID_3
        "datafield[@tag='852']" => -> resource, node {
          id = concatenate_subfields(%w(k h i j m), node, '_')
          resource.id_0 = id unless id.empty?
        },

        # ANW-440: adding additional support for call numbers
        # order of priority is:
        # 099, 090, 092, 096, 098, 050, 082
        # e.g., a value in 099 would be used over a value in 092, etc

        # local non-LC identifier
        "datafield[@tag='099']" => -> resource, node {
          id = concatenate_subfields(('a'..'z'), node, '_')

          if resource.id_0.nil? or resource.id_0.empty?
            resource.id_0 = id unless id.empty?
          end
        },

        # local LC-style identifer
        "datafield[@tag='090']" => -> resource, node {
          id = concatenate_subfields(('a'..'z'), node, '_')

          if resource.id_0.nil? or resource.id_0.empty?
            resource.id_0 = id unless id.empty?
          end
        },

        # Locally Assigned Dewey Call Number
        "datafield[@tag='092']" => -> resource, node {
          id = concatenate_subfields(('a'..'z'), node, '_')

          if resource.id_0.nil? or resource.id_0.empty?
            resource.id_0 = id unless id.empty?
          end
        },

        # Locally NLM-type Call Number
        "datafield[@tag='096']" => -> resource, node {
          id = concatenate_subfields(('a'..'z'), node, '_')

          if resource.id_0.nil? or resource.id_0.empty?
            resource.id_0 = id unless id.empty?
          end
        },

        #  Other Classification Schemes
        "datafield[@tag='098']" => -> resource, node {
          id = concatenate_subfields(('a'..'z'), node, '_')

          if resource.id_0.nil? or resource.id_0.empty?
            resource.id_0 = id unless id.empty?
          end
        },

        # Library of Congress Call Number
        "datafield[@tag='050']" => -> resource, node {
          id = concatenate_subfields(('a'..'z'), node, '_')

          if resource.id_0.nil? or resource.id_0.empty?
            resource.id_0 = id unless id.empty?
          end
        },

        # Dewey Classification Number
        "datafield[@tag='082']" => -> resource, node {
          id = concatenate_subfields(('a'..'z'), node, '_')

          if resource.id_0.nil? or resource.id_0.empty?
            resource.id_0 = id unless id.empty?
          end
        },

        # description rules
        "datafield[@tag='040']/subfield[@code='e']" => :finding_aid_description_rules,

        # language of description
        "datafield[@tag='040']/subfield[@code='b']" => :finding_aid_language,

        # 200s
        "datafield[@tag='210']" => mix(multipart_note('odd', "Abbreviated Title", "{$a: }{$b }{($2)}"), is_fallback_resource_title),

        "datafield[@tag='222']" => mix(multipart_note('odd', "Abbreviated Title", "{$a: }{$b }{($2)}"), is_fallback_resource_title),

        "datafield[@tag='240']" => mix(multipart_note('odd', 'Uniform Title', %q|
                                                $a ({Date of treaty signing-$d; }
                                                {Date of work-$f; }{Medium-$h; }
                                                {Language-$l; }
                                                Medium of performance-$m value;
                                                Arranged statement of performance-$o;
                                                Name of part / section-$p;
                                                Number of part / section-$n; Key for music-$r;
                                                Version-$s; Form subdivision-$k; Miscellaneous-$g)
                                                |), is_fallback_resource_title),

        "datafield[@tag='242']" => multipart_note('odd', 'Translation of Title', "{$a: }{$b }{[$h] }{$n, }{$p, }{$y}){ / $c}"),

        # TITLE
        "datafield[@tag='245']" => -> resource, node {
          resource.title = subfield_template("{$a : }{$b }{[$h] }{$k , }{$n , }{$p , }{$s }{/ $c}", node)

          expression = subfield_template("{$f}", node)
          bulk = subfield_template("{$g}", node)
          unless expression.empty? && bulk.empty?
            if resource.dates[0] && resource.dates[0]['date_type'] != 'bulk' && !expression.empty?
              resource.dates[0]['expression'] = expression
            elsif !expression.empty?
              make(:date) do |date|
               date.label = 'creation'
               date.date_type = 'inclusive'
               date.expression = expression
               resource.dates << date
             end
            end
            unless bulk.empty?
              if resource.dates[0] && resource.dates[0]['date_type'] == 'bulk'
                resource.dates[0]['expression'] = bulk
              else
                make(:date)  do |date|
                  date.label = 'creation'
                  date.date_type = 'bulk'
                  date.expression = bulk
                  resource.dates << date
                end
              end
            end
          else
            resource['_needs_date'] = true
          end
        },

        "datafield[@tag='246'][@ind2='0']" => multipart_note('odd',
                                                             -> node {
                                                               {
                                                                 '0'=>'Portion of title',
                                                                 '1'=>'Parallel title',
                                                                 '2'=>'Distinctive title',
                                                                 '3'=>'Other title',
                                                                 '4'=>'Cover title',
                                                                 '5'=>'Added title page title',
                                                                 '6'=>'Caption title',
                                                                 '7'=>'Running title',
                                                                 '8'=>'Spine title'
                                                               }[node.attr('ind2')]
                                                             },
                                                             "{$a: }{$b }{[$h] }{$f, }{$n }{$p, }{$g})"
                                                             ),

        "datafield[@tag='250']" => multipart_note('odd', 'Edition Statement', "{$a} / {$b}"),

        "datafield[@tag='254']" => multipart_note('odd', 'Musical Presentation Statement', "{$a}"),

        "datafield[@tag='255']" => multipart_note('odd', 'Mathematical map data', %q|
                                            Statement of scale--{$a}; Statement of projection--{$b}; Statement of
                                            coordinates--{$c}; Statement of zone--{$d}; Statement of equinox--{$e};
                                            Ourter G-ring coordinate pairs--{$f}; ExclusionG-ring coordinate pairs--{$g}.
                                            |),

        "datafield[@tag='256']" => singlepart_note('physdesc', 'Computer file Characteristics', "{$a}"),

        "datafield[@tag='257']" => multipart_note('odd', 'Country of Producing Entity for Archival Films', "{$a}"),

        "datafield[@tag='258']" => multipart_note('odd', 'Stamp description', "{$a}, {$b}."),

        "datafield[@tag='260']" => mix(multipart_note('odd', 'Publication Date', "{$c}"), {
                                         "self::datafield" => -> resource, node {
                                           if resource['_needs_date']
                                             make(:date) do |date|
                                               date.label = 'publication'
                                               date.date_type = 'single'
                                               date.expression = node.xpath("subfield[@code='c']")
                                               resource.dates << date
                                             end
                                           else
                                             resource['_needs_date'] = true
                                           end
                                         }
                                       }),

        "datafield[@tag='264']/subfield[@code='c']" => -> resource, node {
                                          if resource['_needs_date']
                                            make(:date) do |date|
                                              date.label = 'publication'
                                              date.date_type = 'single'
                                              date.expression = node.inner_text
                                              resource.dates << date
                                            end
                                          end
                                        },

        # 300s
        # EXTENTS
        "datafield[@tag='300']" => {
          :obj => :extent,
          :rel => :extents,
          :map => {
            "self::datafield" => -> extent, node {
              # ANW-1260
              a_content = node.xpath('.//subfield[@code="a"]')
              f_content = node.xpath('.//subfield[@code="f"]')

              # only $a present - parse with existing method
              if a_content.length > 0 && f_content.empty?
                ext = a_content.first.text
                if ext =~ /^([0-9\.,]+)+\s+(.*)$/
                  extent.number = $1
                  extent.extent_type = $2
                elsif ext =~ /^([0-9\.,]+)/
                  extent.number = $1
                else
                  raise "The extent field (300, #{ext}) could not be parsed."
                end

              # $a and $f present, a must be numeric, f must be an extent value that's present in the extent_extent_type enumeration
              elsif a_content.length > 0 && f_content.length > 0

                # $a must be numeric
                if a_content.inner_text =~ /^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)$/
                  extent.number = a_content.inner_text
                else
                  raise "No numeric value found in field 300, subfield a (#{a_content.inner_text})"
                end

                # remove punctuation and replace underscores with spaces to better match extent_type translation values
                f_content_cleaned = f_content.inner_text.gsub(/[.,\/#!$%^&*;:{}=-_`~()]/, "").gsub("_", " ").downcase
                extent_values = I18n.t('enumerations.extent_extent_type').values.map {|v| v.downcase }

                if extent_values.include?(f_content_cleaned)
                  extent.extent_type = f_content.inner_text
                else
                  raise "Extent type in field 300, subfield f (#{f_content.inner_text}) is not found in the extent type controlled vocabulary."
                end
              end

              # marc doesn't provide data for specifying part of an extent, so use whole by default

              extent.portion = "whole"
              extent.container_summary = subfield_template("{$3: }{$a }{$b, }{$c }({$e, }{$f, }{$g})", node)
            }
          },
        },

        "datafield[@tag='306']" => singlepart_note('physdesc', 'Playing Time', "{$a}"),

        "datafield[@tag='340']" => multipart_note('phystech', 'Physical Medium', %q|
                                            {$3: }{Material base and configuration--$a; }{Dimensions--$b; }
                                            {Materials applied to surface--$c; }{Information recording technique--$d, }
                                            {Support--$e, }{Production rate / ratio--$f, }{Location within medium--$h, }
                                            {Technical specifications of medium--$i}
                                            |),

        "datafield[@tag='342']" => multipart_note('odd',
                                                  -> node {
                                                    label = 'Geospatial Reference Dimension: '
                                                    map = {
                                                      'ind1' => {
                                                        '0' => 'Horizontal coordinate system',
                                                        '1' => 'Vertical coordinate system'
                                                      },
                                                      'ind2' => {
                                                        '0'=>'Geographic',
                                                        '1'=>'Map projection',
                                                        '2'=>'Grid coordinate system',
                                                        '3'=>'Local planar',
                                                        '4'=>'Local',
                                                        '5'=>'Geodetic model',
                                                        '6'=>'Altitude',
                                                        '8'=>'Depth',
                                                      }
                                                    }

                                                    if node.attr('ind1') && node.attr('ind2')
                                                      one = map['ind1'][node.attr('ind1')]
                                                      two = node.attr('ind2') == '7' ? one : map['ind2'][node.attr('ind2')]
                                                      label += "#{one}--#{two}"
                                                    elsif node.attr('ind1')
                                                      label += "#{map['ind1'][node.attr('ind1')]}"
                                                    elsif node.attr('ind2')
                                                      label += "#{map['ind2'][node.attr('ind2')]}"
                                                    end

                                                    label
                                                  },
                                                  %q|
                                            {Name--$a; }{Coordinate or distance units--$b; }{Latitude resolution--$c; }
                                            {Longitude resolution--$d; }{Standard parallel or oblique latitude--$e; }
                                            {Oblique line longitude--$f; }{Longitude of central meridian or projection center--$g; }
                                            {Latitude of projection origin or projection center--$h; }{False easting--$i; }
                                            {False northing--$j; }{Scale factor--$k; }{Height of perspective point above surface--$l; }
                                            {Azimuthal angle--$m; }{Azimuth measure point longitude or straight vertical longitude from pole--$n; }
                                            {Landsat number and path number--$o; }
                                            {Zone identifier--$p; }{Ellipsoid name--$q; }{Semi-major axis--$r; }
                                            {Denominator of flattening ratio--$s; }
                                            {Vertical resolution--$t; }{Vertical encoding method--$u; }
                                            {Local planar, local, or other projection or grid description--$v; }
                                            {Local planar or local georeference information--$w; Reference method used--$2}
                                            |),


        "datafield[@tag='343']" => singlepart_note('physdesc', 'Planar Surface Coordinate System', %q|
                                            {Planar coordinate encoding method--$a; }
                                            {Planar distance units--$b; }
                                            {Abscissa resolution--$c; }{Ordinate resolution--$d; }
                                            {distance resolution--$e; }{Bearing resolution--$f; }
                                            {Bearing units--$g; }{Bearing reference direction--$h; }
                                            {Bearing reference meridian--$i.}
                                            |),

        "datafield[@tag='351']" => multipart_note('arrangement', 'Arrangement', "{$3: }{$a. }{$b. }{$c}"),

        "datafield[@tag='352']" => multipart_note('phystech', 'Digital Graphic Representation', %q|
                                            {Direct reference method--$a; }{Object type--$b; }
                                            {Object count--$c; }{Row count--$d; }{Column count--$e; }
                                            {Vertical count--$f; }{VPF topology level--$g; }{Indirect reference description--$i; }
                                            {Format of the digital image--$q.}|),

        "datafield[@tag='355']" => multipart_note('accessrestrict', 'Security Classification Control',
                                                  %q|{@ind1 }
                                            {Security classification--$a; }{Handling instructions--$b; }
                                            {External dissemination information--$c; }{Downgrading or declassification event--$d; }
                                            {Classification system--$e; }{Country of origin code--$f; }
                                            {Downgrading date--$h; }{Authorization--$j}.|,
                                                  {'ind1' => {
                                                      '0'=>'Document',
                                                      '1'=>'Title',
                                                      '2'=>'Abstract',
                                                      '3'=>'Contents note',
                                                      '4'=>'Author',
                                                      '5'=>'Record',
                                                      '8'=>'Other element'}
                                                  }),

        "datafield[@tag='357']" => multipart_note('odd', 'Originator Dissemination Control', %q|
                                            {Originator control term--$a; }{Originating agency--$b; }
                                            {Authorized recipients of materials--$c; }{Other restrictions--$g}
                                            |),

        # 500s
        "datafield[@tag='500']" => multipart_note('odd', 'General Note', "{$3: }{$a}"),

        "datafield[@tag='501']" => multipart_note('odd', 'With Note', "{$a}"),

        "datafield[@tag='502']" => multipart_note('odd', 'Thesis / Dissertation Note', "{$a}"),

        "datafield[@tag='504']" => bibliography_note_template('Bibliographic References', "{$a }{$b}"),

        "datafield[@tag='505']" => multipart_note('odd', 'Cumulative Index/Finding Aids Note', "{$a}"),

        "datafield[@tag='506']" => multipart_note('accessrestrict', ' Restrictions on Access', "{$3: }{$a, }{$b, }{$c, }{$d, }{$e, }{$u}."),

        "datafield[@tag='507']" => multipart_note('odd', 'Scale Note for Graphic Material', "{$a : }{$b}"),

        "datafield[@tag='508']" => multipart_note('odd', 'Production Credits', "{$a}"),

        "datafield[@tag='510']" => bibliography_note_template('Bibliographic References',
                                                              "{@ind1} -- {$3: }{$a : }{$b : }{$c }{($x)}",
                                                              {'ind1' =>{
                                                                  '0'=>'Coverage unknown',
                                                                  '1'=>'Coverage complete',
                                                                  '2'=>'Coverage is selective',
                                                                  '3'=>'Location in source not given',
                                                                  '4'=>'Location in source given',
                                                                }}),

        "datafield[@tag='511']" => multipart_note('odd', 'Participants / Performers', "{$a}"),

        "datafield[@tag='513']" => multipart_note('scopecontent', 'Type of report', "{$a} {($b)}"),

        "datafield[@tag='514']" => multipart_note('odd', 'Data quality', %q|
                                            {$z: }{Attribute accuracy report--$a; }{Attribute accuracy value--$b; }
                                            {Attribute accuracy explanation--$c; }{Logical consistency report--$d; }
                                            {Completeness report--$e; }{Horizontal position accuracy report--$f; }
                                            {Horizontal position accuracy value--$g; }{Horizontal position accuracy explanation--$h; }
                                            {Vertical positional accuracy report--$i; }{Vertical positional accuracy value--$j; }
                                            {Vertical positional accuracy explanation--$k; }{Cloud cover--$m; }
                                            {Uniform Resource Identifier--$u}.|),


        "datafield[@tag='518']" => multipart_note('odd', 'Date and Time of Event', "{$3: }{$a.}"),

        "datafield[@tag='520'][@ind1!='3' and @ind1!='2' and @ind1!='8']" => multipart_note(
                                                                             'odd',
                                                                             -> node {
                                                                               {'0'=>'Subject', '1'=>'Review'}[node.attr('ind1')] || "Summary"
                                                                             },
                                                                             "{$3: }{$a. }{($u) }{\n$b}"),

        "datafield[@tag='520'][@ind1='2']" => multipart_note('scopecontent', 'Scope and content', "{$3: }{$a. }{($u) }{\n$b}"),

        "datafield[@tag='520'][@ind1='3']" => singlepart_note('abstract', 'Abstract', "{$3: }{$a. }{($u) }{\n$b}"),

        "datafield[@tag='521'][@ind1!='8']" => multipart_note(
                                                              'odd',
                                                              -> node {
                                                                {
                                                                  '0'=>'Reading grade level',
                                                                  '1'=>'Interest age level',
                                                                  '2'=>'Interest grade level',
                                                                  '3'=>'Special audience characteristics',
                                                                  '4'=>'Motivation interest level',
                                                                  '8'=>'No display constant generated'
                                                                }[node.attr('ind1')] || "Audience"
                                                              },
                                                              "{$3: }{$a }{($b)}."),


        "datafield[@tag='522']" => multipart_note('odd', 'Geographic Coverage', "{$a}"),

        "datafield[@tag='524']" => multipart_note('prefercite', 'Preferred Citation', "{$3: }{$a. }{$2}."),

        "datafield[@tag='530']" => multipart_note('altformavail', 'Alternate Form Available', "{$3: }{$a. }{$b. }{$c. }{$d. }{($u)}"),

        "datafield[@tag='533']" => multipart_note('odd', 'Reproduction Note', %q|
                                            {$3: }{Type of reproduction--$a; }{Place of reproduction--$b; }
                                            {Agency responsible for reproduction--$c: }{Date of reproduction--$d. }{Physical description of reproduction--$e. }
                                            {Series statement of reproduction--$f. }{Dates and / or sequential of issues reproduced--$m. }
                                            {Note about reproduction--$n.}|
                                                  ),

        "datafield[@tag='534']" => multipart_note('odd', 'Original Version Note', %q|
                                            {$p: }{$a, }{$t, }{$k, }{$c }{($b). }{$f. }{$e, }{$m. }{$n, }{$l. }{($x), }{($z)}.|),

        "datafield[@tag='535']" => multipart_note('originalsloc', 'Location of Originals Note', %q|
                                            {@ind1: } {$3--}{$a. }{$b, }{$c. }{$d }{($g).}|,
                                                  {'ind1'=>{'1'=>'Holder of originals', '2'=>'Holder of duplicates'}}),

        # FINDING AID SPONSOR
        "datafield[@tag='536']" => -> resource, node {
          resource.finding_aid_sponsor=subfield_template(%q|
                                              {Text of note--$a; }{Contract number--$b; }{Grant number--$c; }
                                              {Undifferentiated number--$d; }{Program element number--$f; }{Task number--$g; }
                                              {Work unit number--$h}|, node)
        },

        "datafield[@tag='538']" => multipart_note('phystech', 'System Details Note', "{$3: }{$a }{($u)}."),

        "datafield[@tag='540']" => multipart_note('userestrict', 'Terms Governing Use and Reproduction', "{$3: }{$a. }{$b. }{$c. }{$d }{($u)}."),

        "datafield[@tag='541']" => multipart_note('acqinfo', 'Immediate Source of Acquisition', %q|
                                            {$3: }{Source of acquisition--$a. }{Address--$b. }{Method of acquisition--$c; }
                                            {Date of acquisition--$d. }{Accession number--$e: }{Extent--$n; }
                                            {Type of unit--$o. }{Owner--$f. }{Purchase price--$h}.|),

        "datafield[@tag='544']" => multipart_note('relatedmaterial', 'Related Archival Materials', %q|
                                            {$3: }{Title--$d. }{Custodian--$a: }
                                            {Address--$b, }{Country--$c. }{Provenance--$e. }{Note--$n}.|,
                                                  {'ind1'=>{'1'=>'Associated Materials', '2'=>'Related Materials'}}),

        "datafield[@tag='545']" => multipart_note(
                                                  'bioghist',
                                                  -> node {
                                                    {
                                                      '0'=>'Biographical sketch',
                                                      '1'=>'Administrative history',
                                                    }[node.attr('ind1')]
                                                  },
                                                  "{$a }{($u)}.{\n$b.}"),

        # ANW-697: Language notes now mapped to language of materials note inside a lang_material record
        "datafield[@tag='546']" => -> resource, node {

          content = subfield_template("{$3: }{$a }{($b)}.", node)

          make(:lang_material) do |lang|
            lang.notes = [{"jsonmodel_type": "note_langmaterial",
                           "type": "langmaterial",
                           "content": [content]}]

            resource.lang_materials << lang

          end

        },

        "datafield[@tag='555']" => multipart_note('otherfindaid', 'Other Finding Aid', "{$a}{; $b}{; $c}{; $d}{; $u}{; $3}."),

        "datafield[@tag='561']" => multipart_note('custodhist', 'Ownership and Custodial History', "{$3: }{$a}."),

        "datafield[@tag='562']" => multipart_note('relatedmaterial', 'Copy and Version Identification', %q|
                                            {$3: }{Identifying markings--$a; }{Copy identification--$b; }{Version identification--$c; }
                                            {Presentation format--$d; }{Number of copies--$e}.|),

        "datafield[@tag='563']" => multipart_note('odd', 'Binding Information', "{$3: }{$a }{($u)}."),

        "datafield[@tag='565']" => singlepart_note('materialspec', 'Case File Characteristics Note', %q|
                                            {$3: }{Number of cases / variables--$a; }{name of variable--$b; }
                                            {Unit of analysis--$c; }{Universe of data--$d; }{Filing scheme or code--$e}.|),

        "datafield[@tag='581']" => bibliography_note_template('Publications About Described Materials', "{$3: }{$a }{($z)}."),

        "datafield[@tag='583']" => multipart_note('processinfo', 'Processing Note', %q|
                                            {Action: $a}{--Action Identification: $b}{--Time/Date of Action: $c}{--Action interval: $d}
                                            {--Contingency for Action: $e}{--Authorization: $f}{--Jurisdiction: $h}
                                            {--Method of action: $i}{--Site of Action: $j}{--Action agent: $k}{--Status: $l}{--Extent: $n}
                                            {--Type of unit: $o}{--URI: $u}{--Non-public note: $x}{--Public note: $z}{--Materials specified: $3}
                                            {--Institution: $5}|.split(/\n+/).map {|l| l.strip }.reject {|l| l.empty? }.join),

        "datafield[@tag='584']" => multipart_note('accruals', 'Accruals', %q|
                                            {Accumulation: $a}{--Frequency of use: $b}{--Materials specified: $3}{--Institution: $5}.|),

        "datafield[starts-with(@tag, '59')]" => multipart_note('odd', 'Local Note'),

        # LINKED AGENTS (PERSON)
        "datafield[@tag='100'][@ind1='0' or @ind1='1']" => mix(person_template, creators),
        "datafield[@tag='700'][@ind1='0' or @ind1='1']" => mix(person_template, sources),

        "datafield[@tag='600'][@ind1='0' or @ind1='1']" => mix(person_template, agent_as_subject),

        # LINKED AGENTS (FAMILY)
        "datafield[@tag='100'][@ind1='3']" => mix(family_template, creators),
        "datafield[@tag='700'][@ind1='3']" => mix(family_template, sources),

        "datafield[@tag='600'][@ind1='3']" => mix(family_template, agent_as_subject),

        # LINKED AGENTS (CORPORATE)
        "datafield[@tag='110']" => mix(corp_template, creators),
        "datafield[@tag='710']" => mix(corp_template, sources),

        "datafield[@tag='111']" => mix(corp_template, creators, corp_variation),
        "datafield[@tag='711']" => mix(corp_template, sources, corp_variation),

        "datafield[@tag='610']" => mix(corp_template, agent_as_subject),

        "datafield[@tag='611']" => mix(corp_template, agent_as_subject, corp_variation),

        #SUBJECTS
        "datafield[@tag='630' or @tag='130' or @tag='730']" => subject_template(
                                                                                -> node {
                                                                                  terms = []
                                                                                  terms << make_term('uniform_title', concatenate_subfields(%w(a d e f g h k l m n o p r s t), node, ' ', true))
                                                                                  node.xpath("subfield").each do |sf|
                                                                                    terms << make_term(
                                                                                                       {
                                                                                                         'v' => 'genre_form',
                                                                                                         'x' => 'topical',
                                                                                                         'y' => 'temporal',
                                                                                                         'z' => 'geographic'
                                                                                                       }[sf.attr('code')], sf.inner_text)
                                                                                  end
                                                                                  terms
                                                                                },
                                                                                sets_subject_source, '430'),

        "datafield[@tag='650' or @tag='150']" => subject_template(
                                                                                -> node {
                                                                                  terms = []
                                                                                  node.xpath("subfield").each do |sf|
                                                                                    terms << make_term(
                                                                                                       {
                                                                                                         'a' => 'topical',
                                                                                                         'b' => 'topical',
                                                                                                         'c' => 'topical',
                                                                                                         'd' => 'topical',
                                                                                                         'v' => 'genre_form',
                                                                                                         'x' => 'topical',
                                                                                                         'y' => 'temporal',
                                                                                                         'z' => 'geographic'
                                                                                                       }[sf.attr('code')], sf.inner_text)
                                                                                  end
                                                                                  terms
                                                                                },
                                                                                sets_subject_source, '450'),

        "datafield[@tag='651' or @tag='151']" => subject_template(
                                                                                -> node {
                                                                                  terms = []
                                                                                  node.xpath("subfield").each do |sf|
                                                                                    terms << make_term(
                                                                                                       {
                                                                                                         'a' => 'geographic',
                                                                                                         'v' => 'genre_form',
                                                                                                         'x' => 'topical',
                                                                                                         'y' => 'temporal',
                                                                                                         'z' => 'geographic'
                                                                                                       }[sf.attr('code')], sf.inner_text)
                                                                                  end
                                                                                  terms
                                                                                },
                                                                                sets_subject_source, '451'),

        "datafield[@tag='655' or @tag='155']" => subject_template(
                                                                                  -> node {
                                                                                    terms = []
                                                                                    # FIXME: subfield `c` not handled
                                                                                    node.xpath("subfield").each do |sf|
                                                                                      terms << make_term(
                                                                                                         {
                                                                                                           'a' => 'genre_form',
                                                                                                           'b' => 'genre_form',
                                                                                                           'v' => 'genre_form',
                                                                                                           'x' => 'topical',
                                                                                                           'y' => 'temporal',
                                                                                                           'z' => 'geographic'
                                                                                                         }[sf.attr('code')], sf.inner_text)
                                                                                    end
                                                                                    terms
                                                                                  },
                                                                                  sets_subject_source, '455'),

        "datafield[@tag='656']" => subject_template(
                                                    -> node {
                                                      terms = []
                                                      node.xpath("subfield").each do |sf|
                                                        terms << make_term(
                                                                           {
                                                                             'a' => 'occupation',
                                                                             'k' => 'genre_form',
                                                                             'v' => 'genre_form',
                                                                             'x' => 'topical',
                                                                             'y' => 'temporal',
                                                                             'z' => 'geographic'
                                                                           }[sf.attr('code')], sf.inner_text)
                                                      end
                                                      terms
                                                    },
                                                    -> node {
                                                      node.attr('ind2') == '7' ? node.xpath("subfield[@code='2']").inner_text : nil
                                                    }),

        "datafield[@tag='657']" => subject_template(
                                                    -> node {
                                                      terms = []
                                                      node.xpath("subfield").each do |sf|
                                                        terms << make_term(
                                                                           {
                                                                             'a' => 'function',
                                                                             'v' => 'genre_form',
                                                                             'x' => 'topical',
                                                                             'y' => 'temporal',
                                                                             'z' => 'geographic'
                                                                           }[sf.attr('code')], sf.inner_text)
                                                      end
                                                      terms
                                                    },
                                                    -> node {
                                                      node.attr('ind2') == '7' ? node.xpath("subfield[@code='2']").inner_text : nil
                                                    }),

        "datafield[starts-with(@tag, '69')]" => subject_template(
                                                                 -> node {
                                                                   terms = []
                                                                   hsh = {}
                                                                   node.xpath("subfield").each do |subnode|
                                                                     code = subnode.attr('code')
                                                                     val = subnode.inner_text
                                                                     hsh[code] ||= []
                                                                     hsh[code] << val
                                                                   end
                                                                   srtd_keys = hsh.keys.sort do |one, two|
                                                                     if one == '3'
                                                                       -1
                                                                     elsif two == '3'
                                                                       1
                                                                     elsif one == 'a'
                                                                       -1
                                                                     elsif two == 'a'
                                                                       1
                                                                     else
                                                                       one <=> two
                                                                     end
                                                                   end
                                                                   srtd_keys.each do |k|
                                                                     if hsh[k] and !hsh[k].empty?
                                                                       hsh[k].each do |t|
                                                                         terms << make_term('topical', t)
                                                                       end
                                                                     end
                                                                   end
                                                                   terms
                                                                 },
                                                                 -> node {'local'},
                                                                 ),

        #700s
        "datafield[@tag='720']['@ind1'='1']" => mix(agent_template,
                                                    {
                                                      :obj => :agent_person,
                                                      :map => {
                                                        "self::datafield" => {
                                                          :obj => :name_person,
                                                          :rel => :names,
                                                          :map => {
                                                            "subfield[@code='a']" => :primary_name,
                                                          },
                                                          :defaults => {
                                                            :source => 'ingest',
                                                          }
                                                        }
                                                      }
                                                    }),

        "datafield[@tag='720']['@ind1'='2']" => mix(agent_template,
                                                    {
                                                      :obj => :agent_corporate_entity,
                                                      :map => {
                                                        "self::datafield" => {
                                                          :obj => :name_corporate_entity,
                                                          :rel => :names,
                                                          :map => {
                                                            "subfield[@code='a']" => :primary_name,
                                                          },
                                                          :defaults => {
                                                            :source => 'ingest',
                                                          }
                                                        }
                                                      }
                                                    }),

        "datafield[@tag='740']" => multipart_note('odd', 'Related / Analytical Title', "{$a }{[$h] }{$p, }{$n}."),

        "datafield[@tag='752']" => subject_template(
                                                    -> node {
                                                      terms = []
                                                      %w(a b c d f g).each do |code|
                                                        val = node.xpath("subfield[@code='#{code}']").inner_text
                                                        terms << make_term('geographic', val)
                                                      end

                                                      terms
                                                    },
                                                    -> node {
                                                      node.xpath("subfield[@code='2']").inner_text
                                                    }),

        "datafield[@tag='754']" => subject_template(
                                                    -> node {
                                                      term = concatenate_subfields(%w(a c d x z), node, '--')
                                                      [make_term('topical', term)]
                                                    },
                                                    -> node {
                                                      node.xpath("subfield[@code='2']").inner_text
                                                    }),

        # last minute checks for the top-level record
        "self::record" => -> resource, node {

          if !resource.title && resource['_fallback_titles'] && !resource['_fallback_titles'].empty?
            resource.title = resource['_fallback_titles'].shift
          end

          if resource.id_0.nil? or resource.id.empty?
            resource.id_0 = "imported-#{SecureRandom.uuid}"
          end
        }
      }
    }
  end
end
