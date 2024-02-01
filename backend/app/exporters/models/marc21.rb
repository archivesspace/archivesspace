# coding: utf-8
class MARCModel < ASpaceExport::ExportModel
  model_for :marc21

  include JSONModel

  def self.df_handler(name, tag, ind1, ind2, code)
    define_method(name) do |val|
      df(tag, ind1, ind2).with_sfs([code, val])
    end
    name.to_sym
  end

  @archival_object_map = {
    [:repository, :finding_aid_language] => :handle_repo_code,
    [:title, :linked_agents, :dates] => :handle_title,
    :linked_agents => :handle_agents,
    :subjects => :handle_subjects,
    :extents => :handle_extents,
    :lang_materials => :handle_languages
  }

  @resource_map = {
    [:id_0, :id_1, :id_2, :id_3] => :handle_id,
    [:ead_location, :publish, :uri, :slug] => :handle_ead_loc,
    [:ark_name] => :handle_ark,
    :notes => :handle_notes,
    :finding_aid_description_rules => df_handler('fadr', '040', ' ', ' ', 'e')
  }

  # ANW-1416: Maps ISO-3166 country code to MARC country code
  ISO_3166_TO_MARC = {"AE" => "ts", "AF" => "af", "AG" => "aq", "AI" => "ag", "AL" => "aa", "AM" => "ai", "AO" => "ao", "AQ" => "ay", "AR" => "ag", "AS" => "as", "AT" => "au", "AU" => "at", "AW" => "aw", "AX" => "xx", "AZ" => "aj", "BA" => "bn", "BB" => "bb", "BD" => "bg", "BE" => "be", "BF" => "xx", "BG" => "bu", "BH" => "ba", "BI" => "bd", "BJ" => "dm", "BL" => "sc", "BM" => "bm", "BN" => "bx", "BO" => "bo", "BQ" => "xx", "BR" => "bl", "BS" => "bf", "BT" => "bt", "BV" => "bv", "BW" => "bs", "BY" => "bw", "BZ" => "bh", "CA" => "xxc", "CC" => "xb", "CD" => "cg", "CF" => "cx", "CG" => "cf", "CH" => "sz", "CI" => "iv", "CK" => "cw", "CL" => "cl", "CM" => "cm", "CN" => "cc", "CO" => "ck", "CR" => "cr", "CU" => "cu", "CV" => "cv", "CW" => "co", "CX" => "xa", "CY" => "cy", "CZ" => "xr", "DE" => "gw", "DJ" => "ft", "DK" => "dk", "DM" => "dq", "DO" => "dr", "DZ" => "ae", "EC" => "ec", "EE" => "er", "EG" => "ua", "EH" => "ss", "ER" => "ea", "ES" => "sp", "ET" => "et", "FI" => "fi", "FJ" => "fj", "FK" => "fk", "FM" => "fm", "FO" => "fa", "FR" => "fr", "GA" => "go", "GB" => "xxk", "GD" => "gd", "GE" => "gs", "GF" => "gv", "GG" => "gg", "GH" => "gh", "GI" => "gi", "GL" => "gl", "GM" => "gm", "GN" => "gv", "GP" => "gp", "GQ" => "eg", "GR" => "gr", "GS" => "xs", "GT" => "gt", "GU" => "gu", "GW" => "pg", "GY" => "gy", "HK" => "xx", "HM" => "hm", "HN" => "ho", "HR" => "ci", "HT" => "ht", "HU" => "hu", "ID" => "io", "IE" => "ie", "IL" => "is", "IM" => "im", "IN" => "ii", "IO" => "bi", "IQ" => "iq", "IR" => "ir", "IS" => "ic", "IT" => "it", "JE" => "je", "JM" => "jm", "JO" => "jo", "JP" => "ja", "KE" => "ke", "KG" => "kg", "KH" => "cb", "KI" => "gb", "KM" => "cq", "KN" => "xd", "KP" => "kn", "KR" => "ko", "KW" => "ku", "KY" => "cj", "KZ" => "kz", "LA" => "xx", "LB" => "le", "LC" => "xk", "LI" => "lh", "LK" => "ce", "LR" => "lb", "LS" => "lo", "LT" => "li", "LU" => "lu", "LV" => "lv", "LY" => "ly", "MA" => "mr", "MC" => "mc", "MD" => "mv", "ME" => "mo", "MF" => "st", "MG" => "mg", "MH" => "xe", "MK" => "xn", "ML" => "ml", "MM" => "br", "MN" => "mp", "MO" => "xx", "MP" => "nw", "MQ" => "mq", "MR" => "mu", "MS" => "mj", "MT" => "mm", "MU" => "mf", "MV" => "xc", "MW" => "mw", "MX" => "mx", "MY" => "my", "MZ" => "mz", "NA" => "sx", "NC" => "nl", "NE" => "ng", "NF" => "nx", "NG" => "nr", "NI" => "nq", "NL" => "ne", "NO" => "no", "NP" => "np", "NR" => "nu", "NU" => "xh", "NZ" => "nz", "OM" => "mk", "PA" => "pn", "PE" => "pe", "PF" => "fp", "PG" => "pp", "PH" => "ph", "PK" => "pk", "PL" => "pl", "PM" => "xl", "PN" => "pc", "PR" => "pr", "PS" => "xx", "PT" => "po", "PW" => "pw", "PY" => "py", "QA" => "qa", "RE" => "re", "RO" => "rm", "RS" => "rb", "RU" => "ru", "RW" => "rw", "SA" => "su", "SB" => "bp", "SC" => "se", "SD" => "sj", "SE" => "sw", "SG" => "si", "SH" => "xj", "SI" => "xv", "SJ" => "xx", "SK" => "xo", "SL" => "si", "SM" => "sm", "SN" => "sg", "SO" => "so", "SR" => "sr", "SS" => "sd", "ST" => "sf", "SV" => "es", "SX" => "sn", "SY" => "sy", "SZ" => "xx", "TC" => "tc", "TD" => "cd", "TF" => "xx", "TG" => "tg", "TH" => "th", "TJ" => "ta", "TK" => "tl", "TL" => "em", "TM" => "tk", "TN" => "ti", "TO" => "to", "TR" => "tu", "TT" => "tr", "TV" => "tv", "TW" => "xx", "TZ" => "tz", "UA" => "un", "UG" => "ug", "UM" => "xxu", "US" => "xxu", "UY" => "uy", "UZ" => "uz", "VA" => "vc", "VC" => "xm", "VE" => "ve", "VG" => "vb", "VI" => "vi", "VN" => "vm", "VU" => "nn", "WF" => "wf", "WS" => "ws", "YE" => "ye", "YT" => "ot", "ZA" => "sa", "ZM" => "za", "ZW" => "rh"}

  attr_accessor :leader_string
  attr_accessor :controlfield_string

  @@datafield = Class.new do

    attr_accessor :tag
    attr_accessor :ind1
    attr_accessor :ind2
    attr_accessor :subfields


    def initialize(*args)
      @tag, @ind1, @ind2 = *args
      @subfields = []
    end

    def with_sfs(*sfs)
      sfs.each do |sf|
        subfield = @@subfield.new(*sf)
        @subfields << subfield unless subfield.empty?
      end

      return self
    end

  end

  @@subfield = Class.new do

    attr_accessor :code
    attr_accessor :text

    def initialize(*args)
      @code, @text = *args
    end

    def empty?
      if @text && !@text.empty?
        false
      else
        true
      end
    end
  end

  def initialize(include_unpublished = false)
    @datafields = {}
    @include_unpublished = include_unpublished
  end

  def datafields
    @datafields.map {|k, v| v}
  end

  def include_unpublished?
    @include_unpublished
  end


  def self.from_aspace_object(obj, opts = {})
    self.new(opts[:include_unpublished])
  end

  # 'archival object's in the abstract
  def self.from_archival_object(obj, opts = {})
    marc = self.from_aspace_object(obj, opts)
    marc.apply_map(obj, @archival_object_map)

    marc
  end

  # subtypes of 'archival object':

  def self.from_resource(obj, opts = {})
    marc = self.from_archival_object(obj, opts)
    marc.apply_map(obj, @resource_map)
    marc.leader_string = "00000np$aa2200000 u 4500"
    marc.leader_string[7] = obj.level == 'item' ? 'm' : 'c'

    marc.controlfield_string = assemble_controlfield_string(obj)

    marc
  end


  def self.assemble_controlfield_string(obj)
    date = obj.dates[0] || {}
    string = obj['system_mtime'].scan(/\d{2}/)[1..3].join('')
    string += date['date_type'] == 'single' ? 's' : 'i'
    string += date['begin'] ? date['begin'][0..3] : "    "
    string += date['end'] ? date['end'][0..3] : "    "

    repo = obj['repository']['_resolved']

    if repo.has_key?('country') && !repo['country'].empty?
      string += (ISO_3166_TO_MARC[repo['country']] || "xx")
    else
      string += "xx"
    end

    # If only one Language and Script subrecord its code value should be exported in the MARC 008 field position 35-37; If more than one Language and Script subrecord is recorded, a value of "mul" should be exported in the MARC 008 field position 35-37.
    lang_materials = obj.lang_materials
    languages = lang_materials.map {|l| l['language_and_script']}.compact
    langcode = languages.count == 1 ? languages[0]['language'] : 'mul'

    # variable number of spaces needed since country code could have 2 or 3 chars
    (35-(string.length)).times { string += ' ' }
    string += (langcode || '|||')
    string += ' d'

    string
  end


  def df!(*args)
    @sequence ||= 0
    @sequence += 1
    @datafields[@sequence] = @@datafield.new(*args)
    @datafields[@sequence]
  end


  def df(*args)
    if @datafields.has_key?(args.to_s)
      @datafields[args.to_s]
    else
      @datafields[args.to_s] = @@datafield.new(*args)
      @datafields[args.to_s]
    end
  end


  def handle_id(*ids)
    ids.reject! {|i| i.nil? || i.empty?}
    df('099', ' ', ' ').with_sfs(['a', ids.join('.')])
  end


  def handle_title(title, linked_agents, dates)
    creator = linked_agents.find {|a| a['role'] == 'creator'}
    date_codes = []

    # process dates first, if defined.
    unless dates.empty?
      dates = [["single", "inclusive", "range"], ["bulk"]].map {|types|
        dates.find {|date| types.include? date['date_type'] }
      }.compact

      dates.each do |date|
        code, val = nil
        code = date['date_type'] == 'bulk' ? 'g' : 'f'
        if date['expression']
          val = date['expression']
        elsif date['end']
          val = "#{date['begin']} - #{date['end']}"
        else
          val = "#{date['begin']}"
        end
        date_codes.push([code, val])
      end
    end

    ind1 = creator.nil? ? "0" : "1"
    if date_codes.length > 0
      # we want to pass in all our date codes as separate subfield tags
      # e.g., with_sfs(['a', title], [code1, val1], [code2, val2]... [coden, valn])
      df('245', ind1, '0').with_sfs(['a', title + ","], *date_codes)
    else
      df('245', ind1, '0').with_sfs(['a', title])
    end
  end


  def handle_languages(lang_materials)
    # ANW-697: The Language subrecord code values should be exported in repeating subfield $a entries in the MARC 041 field.

    languages = lang_materials.map {|l| l['language_and_script']}.compact

    languages.each do |language|

      df('041', ' ', ' ').with_sfs(['a', language['language']])

    end

    # ANW-697: Language Text subrecords should be exported in the MARC 546 subfield $a

    language_notes = lang_materials.map {|l| l['notes']}.compact.reject {|e| e == [] }

    if language_notes
      language_notes.each do |note|
        handle_notes(note)
      end
    end
  end


  def handle_dates(dates)
    return false if dates.empty?

    dates = [["single", "inclusive", "range"], ["bulk"]].map {|types|
      dates.find {|date| types.include? date['date_type'] }
    }.compact

    dates.each do |date|
      code = date['date_type'] == 'bulk' ? 'g' : 'f'
      val = nil
      if date['expression'] && date['date_type'] != 'bulk'
        val = date['expression']
      elsif date['date_type'] == 'single'
        val = date['begin']
      else
        val = "#{date['begin']} - #{date['end']}"
      end

      df('245', '1', '0').with_sfs([code, val])
    end
  end

  def handle_repo_code(repository, *finding_aid_language)
    repo = repository['_resolved']
    return false unless repo

    sfa = repo['org_code'] ? repo['org_code'] : "Repository: #{repo['repo_code']}"

    # ANW-529: options for 852 datafield:
    # 1.) $a => org_code || repo_name
    # 2.) $a => $parent_institution_name && $b => repo_name

    if repo['parent_institution_name']
      subfields_852 = [
                        ['a', repo['parent_institution_name']],
                        ['b', repo['name']]
                      ]
    elsif repo['org_code']
      subfields_852 = [
                        ['a', repo['org_code']],
                      ]
    else
      subfields_852 = [
                        ['a', repo['name']]
                      ]
    end

    df('852', ' ', ' ').with_sfs(*subfields_852)

    df('040', ' ', ' ').with_sfs(['a', repo['org_code']], ['b', finding_aid_language[0]], ['c', repo['org_code']])

    if repo['org_code']
      df('049', ' ', ' ').with_sfs(['a', repo['org_code']])
    end
  end

  def source_to_code(source)
    ASpaceMappings::MARC21.get_marc_source_code(source)
  end

  def handle_subjects(subjects)
    subjects.each do |link|
      subject = link['_resolved']
      term, *terms = subject['terms']
      code, ind2 =  case term['term_type']
                    when 'uniform_title'
                      ['630', source_to_code(subject['source'])]
                    when 'temporal'
                      ['648', source_to_code(subject['source'])]
                    when 'topical'
                      ['650', source_to_code(subject['source'])]
                    when 'geographic', 'cultural_context'
                      ['651', source_to_code(subject['source'])]
                    when 'genre_form', 'style_period'
                      ['655', source_to_code(subject['source'])]
                    when 'occupation'
                      ['656', '7']
                    when 'function'
                      ['656', '7']
                    else
                      ['650', source_to_code(subject['source'])]
                    end
      sfs = [['a', term['term']]]

      terms.each do |t|
        tag = case t['term_type']
              when 'uniform_title'; 't'
              when 'genre_form', 'style_period'; 'v'
              when 'topical', 'cultural_context'; 'x'
              when 'temporal'; 'y'
              when 'geographic'; 'z'
              end
        sfs << [tag, t['term']]
      end

      if ind2 == '7'
        sfs << ['2', subject['source']]
      end

      sfs << ['0', subject['authority_id']]

      ind1 = code == '630' ? "0" : " "
      df!(code, ind1, ind2).with_sfs(*sfs)
    end
  end


  def handle_primary_creator(linked_agents)
    # ANW-504: get look for primary flag and creator role to find primary agent
    primary_creator = linked_agents.find {|a| a['is_primary'] && a['role'] == 'creator'}

    # use primary creator as 1xx agent, if present
    link = nil
    if primary_creator
      link = primary_creator
    else
      # otherwise, use first found with role = creator
      link = linked_agents.find {|a| a['role'] == 'creator'}
    end


    return nil unless link
    return nil unless link["_resolved"]["publish"] || @include_unpublished

    creator = link['_resolved']
    name = creator['display_name']

    ind2 = ' '

    relator_sfs = []
    if link['relator']
      handle_relators(relator_sfs, link['relator'])
    else
      relator_sfs << ['e', 'creator']
    end

    case creator['agent_type']

    when 'agent_corporate_entity'
      code = '110'
      ind1 = '2'
      sfs = gather_agent_corporate_subfield_mappings(name, relator_sfs, creator)

    when 'agent_person'
      ind1  = name['name_order'] == 'direct' ? '0' : '1'
      code = '100'
      sfs = gather_agent_person_subfield_mappings(name, relator_sfs, creator)

    when 'agent_family'
      code = '100'
      ind1 = '3'
      sfs = gather_agent_family_subfield_mappings(name, relator_sfs, creator)

    end

    df(code, ind1, ind2).with_sfs(*sfs)
  end

  # TODO: DRY this up
  # this method is very similair to handle_primary_creator and handle_agents
  def handle_other_creators(linked_agents)
    primary_creator = linked_agents.find {|a| a['is_primary'] && a['role'] == 'creator'}

    # if there is NOT a primary creator, automatically exclude the first in the list
    # of creators to get 7xx tags since it was chosen as primary in #handle_primary_creator above

    if primary_creator
      creators = linked_agents.select {|a| a['role'] == 'creator'} || []
    else
      creators = linked_agents.select {|a| a['role'] == 'creator'}[1..-1] || []
    end

    creators = creators + linked_agents.select {|a| a['role'] == 'source'}

    creators.each_with_index do |link, i|
      next unless link["_resolved"]["publish"] || @include_unpublished
      next if link['is_primary']

      creator = link['_resolved']
      name = creator['display_name']
      role = link['role']

      relator_sfs = []
      if link['relator']
        handle_relators(relator_sfs, link['relator'])
      elsif role == 'source'
        relator_sfs << ['e', 'former owner']
      else
        relator_sfs << ['e', 'creator']
      end

      ind2 = ' '

      case creator['agent_type']

      when 'agent_corporate_entity'
        code = '710'
        ind1 = '2'
        sfs = gather_agent_corporate_subfield_mappings(name, relator_sfs, creator)

      when 'agent_person'
        ind1  = name['name_order'] == 'direct' ? '0' : '1'
        code = '700'
        sfs = gather_agent_person_subfield_mappings(name, relator_sfs, creator)

      when 'agent_family'
        ind1 = '3'
        code = '700'
        sfs = gather_agent_family_subfield_mappings(name, relator_sfs, creator)

      end

      df(code, ind1, ind2, i).with_sfs(*sfs)
    end
  end


  def handle_agents(linked_agents)
    handle_primary_creator(linked_agents)
    handle_other_creators(linked_agents)

    subjects = linked_agents.select {|a| a['role'] == 'subject'}

    subjects.each_with_index do |link, i|
      next unless link["_resolved"]["publish"] || @include_unpublished

      subject = link['_resolved']
      name = subject['display_name']
      terms = link['terms']
      ind2 = source_to_code(name['source'])

      relator_sfs = []
      if link['relator']
        handle_relators(relator_sfs, link['relator'])
      end

      case subject['agent_type']

      when 'agent_corporate_entity'
        code = '610'
        ind1 = '2'
        sfs = gather_agent_corporate_subfield_mappings(name, relator_sfs, subject, terms)

      when 'agent_person'
        ind1  = name['name_order'] == 'direct' ? '0' : '1'
        code = '600'
        sfs = gather_agent_person_subfield_mappings(name, relator_sfs, subject, terms)

      when 'agent_family'
        code = '600'
        ind1 = '3'
        sfs = gather_agent_family_subfield_mappings(name, relator_sfs, subject, terms)

      when 'agent_software'
        code = '653'
        ind1 = ' '
        sfs = [['a', name['software_name']]]

      end

      # ANW-825: Don't export $0 if $v, $x, $y, or $z are present
      sfs.reject! {|k| k[0] == 0 } if (['v', 'x', 'y', 'z'] - sfs.map { |k| k[0] }).length < 4

      if ind2 == '7'
        sfs << ['2', subject['names'].first['source']]
      end

      df(code, ind1, ind2, i).with_sfs(*sfs)
    end
  end


  def handle_relators(relator_sfs, link)
    relator = I18n.t("enumerations.linked_agent_archival_record_relators.#{link}")
    relator_sfs << ['4', link]
    unless relator.to_s.include?('translation missing')
      relator_sfs << ['e', relator]
    end

    return relator_sfs
  end


  def handle_agent_terms(terms)
    sfs = []
    terms.each do |t|
      tag = case t['term_type']
            when 'uniform_title'; 't'
            when 'genre_form', 'style_period'; 'v'
            when 'topical', 'cultural_context'; 'x'
            when 'temporal'; 'y'
            when 'geographic'; 'z'
            end
      next if tag.nil?
      sfs << [(tag), t['term']]
    end

    sfs
  end


  def handle_notes(notes)
    notes.each do |note|
      prefix =  case note['type']
                when 'dimensions'; "Dimensions"
                when 'physdesc'; "Physical Description note"
                when 'materialspec'; "Material Specific Details"
                when 'physloc'; "Location of resource"
                when 'phystech'; "Physical Characteristics / Technical Requirements"
                when 'physfacet'; "Physical Facet"
                when 'processinfo'; "Processing Information"
                when 'separatedmaterial'; "Materials Separated from the Resource"
                else; nil
                end

      marc_args = case note['type']

                  when 'arrangement', 'fileplan'
                    ['351', 'a']
                  when 'odd', 'dimensions', 'physdesc', 'materialspec', 'physloc', 'phystech', 'physfacet', 'processinfo', 'separatedmaterial'
                    ['500', 'a']
                  when 'accessrestrict'
                    ['506', 'a']
                  when 'scopecontent'
                    ['520', '2', ' ', 'a']
                  when 'abstract'
                    ['520', '3', ' ', 'a']
                  when 'prefercite'
                    ['524', ' ', ' ', 'a']
                  when 'acqinfo'
                    ind1 = note['publish'] ? '1' : '0'
                    ['541', ind1, ' ', 'a']
                  when 'relatedmaterial'
                    ['544', 'd']
                  when 'bioghist'
                    ['545', 'a']
                  when 'custodhist'
                    ind1 = note['publish'] ? '1' : '0'
                    ['561', ind1, ' ', 'a']
                  when 'appraisal'
                    ind1 = note['publish'] ? '1' : '0'
                    ['583', ind1, ' ', 'a']
                  when 'accruals'
                    ['584', 'a']
                  when 'altformavail'
                    ['535', '2', ' ', 'a']
                  when 'originalsloc'
                    ['535', '1', ' ', 'a']
                  when 'userestrict', 'legalstatus'
                    ['540', 'a']
                  when 'langmaterial'
                    ['546', 'a']
                  when 'otherfindaid'
                    ['555', '0', ' ', 'a']
                  else
                    nil
                  end

      unless marc_args.nil?
        text = prefix ? "#{prefix}: " : ""
        text += ASpaceExport::Utils.extract_note_text(note, @include_unpublished, true)

        # only create a tag if there is text to show (e.g., marked published or exporting unpublished)
        if text.length > 0
          df!(*marc_args[0...-1]).with_sfs([marc_args.last, *Array(text)])
        end
      end

      # ANW-1350: Export bibliography notes to 581
      # Bibliography notes have a different structure than the notes handled above, so they are processed separately

      if note['jsonmodel_type'] == "note_bibliography"
        if note['publish'] || @include_unpublished
          note['content'].each do |c|
            df!('581', ' ', ' ').with_sfs(['a', c])
          end

          note['items'].each do |i|
            df!('581', ' ', ' ').with_sfs(['a', i])
          end
        end
      end
    end
  end


  def handle_extents(extents)
    extents.each do |ext|
      e = ext['number']
      t = "#{I18n.t('enumerations.extent_extent_type.'+ext['extent_type'], :default => ext['extent_type'])}"

      if ext['container_summary']
        t << " (#{ext['container_summary']})"
      end

      df!('300').with_sfs(['a', e], ['f', t])
    end
  end

  # 3/28/18: Updated: ANW-318
  # 4/7/22: Updated: ANW-1071
  def handle_ead_loc(ead_loc, publish, uri, slug)
    # If there is EADlocation
    #<datafield tag="856" ind1="4" ind2="2">
    #  <subfield code="z">Finding aid online:</subfield>
    #  <subfield code="u">EADlocation</subfield>
    #</datafield>
    # if config option is set, output a second 856 with slugged (or not) PUI URL as long as it's not the same as the EADLocation

    #<datafield tag="856" ind1="4" ind2="2">
    #  <subfield code="z">Finding aid online:</subfield>
    #  <subfield code="u">slugged URL</subfield>
    #</datafield>

    if ead_loc && !ead_loc.empty?
      df('856', '4', '2').with_sfs(
                                    ['z', "Finding aid online:"],
                                    ['u', ead_loc]
                                  )
    end

    if AppConfig[:enable_public] && AppConfig[:include_pui_finding_aid_urls_in_marc_exports] && publish

      if AppConfig[:use_human_readable_urls] &&
         AppConfig[:use_slug_finding_aid_urls_in_marc_exports]

        rec_type = uri.split('/')[3]
        link = AppConfig[:public_proxy_url] + "/#{rec_type}/#{slug}"
      else
        link = AppConfig[:public_proxy_url] + uri
      end

      unless link == ead_loc
        df!('856', '4', '2').with_sfs(
                                  ['z', "Finding aid online:"],
                                  ['u', link]
                                )
      end
    end
  end

  def handle_ark(ark_name)
    return if ark_name.nil?
    return unless [:arks_enabled]

    # If ARKs are enabled, add an 856
    #<datafield tag="856" ind1="4" ind2="2">
    #  <subfield code="z">Archival Resource Key:</subfield>
    #  <subfield code="u">ARK URL</subfield>
    #</datafield>

    if ark_url = ark_name['current']
      df('856', '4', '2').with_sfs(
        ['z', "Archival Resource Key:"],
        ['u', ark_url]
      ) unless ark_url.nil? || ark_url.empty?

    end
  end

  private


  def apply_terminal_punctuation(name_fields)
    # The value of the final subfield must end in a period or parens
    # as long as it is not $0, $2, or $4 which don't receive
    # terminal punctuation.
    sub_store = name_fields.reject! {|x| [0, 2, 4].include?(x[0][0]) }
    unless ['.', ')'].include?(name_fields[-1][1][-1])
      name_fields[-1][1] << "."
    end

    name_fields.push(sub_store) unless sub_store.nil?
  end


  def prepare_role_subfields(role_info)
    if role_info.nil? || role_info.empty?
      subfield_e = nil
      subfield_4 = nil
    else
      subfield_e = role_info.select { |k| k[0]=="e" }.flatten
      subfield_4 = role_info.select { |k| k[0]=="4" }.flatten
    end

    return subfield_e, subfield_4
  end

  # search the array of hashes for name for first key named 'authority_id'
  # if found, return it. Otherwise, return nil.
  def find_authority_id(names)
    value_found = nil

    names.each do |name|
      if name['authority_id']
        value_found = name['authority_id']
        break;
      end
    end

    return value_found
  end


  # name fields looks something this:
  # [["a", "Dick, Philp K."], ["b", nil], ["c", "see"], ["d", "10-1-1980"], ["g", nil], ["q", nil], ["4", "aut"]]
  def handle_agent_person_punctuation(name_fields)
    #The value of subfields g and q must be enclosed in parentheses.
    ['g', 'q'].each do |sf|
      index = name_fields.find_index {|a| a[0] == sf}
      unless !index
        name_fields[index][1] = "(#{name_fields[index][1]})"
      end
    end

    #If subfield $c, $d, or $e is present, the value of the preceding subfield must end in a comma.
    ['c', 'd', 'e'].each do |subfield|
      s_index = name_fields.find_index {|a| a[0] == subfield}

      # check if $subfield is present
      unless !s_index || s_index == 0
        preceding_index = s_index - 1

        # find preceding field and append a comma if there isn't one there already
        unless name_fields[preceding_index][1][-1] == ','
          name_fields[preceding_index][1] << ','
        end
      end
    end

    apply_terminal_punctuation(name_fields)

    return name_fields
  end

  def get_primary_agent_record_identifier(agent)
    # ANW-1414: add primary agent_record_identifier if present
    primary_identifier_record = agent['agent_record_identifiers'].first {|ari| ari['primary_identifier'] == true }

    if primary_identifier_record
      return primary_identifier_record['record_identifier']
    else
      return nil
    end
  end


  def gather_agent_person_subfield_mappings(name, role_info, agent, terms=nil)
    joint = name['name_order'] == 'direct' ? ' ' : ', '
    name_parts = [name['primary_name'], name['rest_of_name']].reject {|i| i.nil? || i.empty?}.join(joint)

    subfield_e, subfield_4 = prepare_role_subfields(role_info)
    number      = name['number'] rescue nil
    extras      = %w(prefix title suffix).map {|prt| name[prt]}.compact.join(', ') rescue nil
    dates       = name['dates'] rescue nil
    qualifier   = name['qualifier'] rescue nil
    fuller_form = name['fuller_form'] rescue nil
    primary_identifier = get_primary_agent_record_identifier(agent)

    name_fields = [
                   ["a", name_parts],
                   ["b", number],
                   ["c", extras],
                   ["d", dates],
                   subfield_e,
                   ["g", qualifier],
                   ["q", fuller_form],
                   ["0", primary_identifier],
                  ].compact.reject {|a| a[1].nil? || a[1].empty?}

    unless terms.nil?
      name_fields.concat handle_agent_terms(terms)
    end

    name_fields = handle_agent_person_punctuation(name_fields)
    name_fields.push(subfield_4) unless subfield_4.nil?

    authority_id = find_authority_id(agent['names'])
    subfield_0 = authority_id ? [0, authority_id] : nil
    name_fields.push(subfield_0) unless subfield_0.nil?

    return name_fields
  end

    #For family types
  def handle_agent_family_punctuation(name_fields)
    # TODO: DRY this up eventually. Leaving it as it is for now in case the logic changes.
    #If subfield $d is present, the value of the preceding subfield must end in a colon.
    #If subfield $c is present, the value of the preceding subfield must end in a colon.
    #If subfield $e is present, the value of the preceding subfield must end in a comma.
    ['d', 'c', 'e'].each do |subfield|
      s_index = name_fields.find_index {|a| a[0] == subfield}

      # check if $subfield is present

      unless !s_index || s_index == 0
        preceding_index = s_index - 1

        # find preceding field and append a comma if there isn't one there already
        unless name_fields[preceding_index][1][-1] == ","
          name_fields[preceding_index][1] << ","
        end
      end
    end

    apply_terminal_punctuation(name_fields)

    return name_fields
  end


  def gather_agent_family_subfield_mappings(name, role_info, agent, terms=nil)
    subfield_e, subfield_4 = prepare_role_subfields(role_info)
    family_name = name['family_name'] rescue nil
    qualifier   = name['qualifier'] rescue nil
    dates       = name['dates'] rescue nil
    primary_identifier = get_primary_agent_record_identifier(agent)

    name_fields = [
                    ['a', family_name],
                    ['d', dates],
                    ['c', qualifier],
                    subfield_e,
                    ["0", primary_identifier],
                  ].compact.reject {|a| a[1].nil? || a[1].empty?}

    unless terms.nil?
      name_fields.concat handle_agent_terms(terms)
    end

    name_fields = handle_agent_family_punctuation(name_fields)
    name_fields.push(subfield_4) unless subfield_4.nil?

    authority_id = find_authority_id(agent['names'])
    subfield_0 = authority_id ? [0, authority_id] : nil
    name_fields.push(subfield_0) unless subfield_0.nil?

    return name_fields
  end

    #For corporation types
    # TODO: DRY this up eventually. Leaving it as it is for now in case the logic changes.
  def handle_agent_corporate_punctuation(name_fields)
    name_fields.sort! {|a, b| a[0][0] <=> b[0][0]}

    # The value of subfield g must be enclosed in parentheses.
    g_index = name_fields.find_index {|a| a[0] == "g"}
    unless !g_index
      name_fields[g_index][1] = "(#{name_fields[g_index][1]})"
    end

    # The value of subfield n must be enclosed in parentheses.
    n_index = name_fields.find_index {|a| a[0] == "n"}
    unless !n_index
      name_fields[n_index][1] = "(#{name_fields[n_index][1]})"
    end

    #If subfield $e is present, the value of the preceding subfield must end in a comma.
    #If subfield $n is present, the value of the preceding subfield must end in a comma.
    #If subfield $g is present, the value of the preceding subfield must end in a comma.
    ['e', 'n', 'g'].each do |subfield|
      s_index = name_fields.find_index {|a| a[0] == subfield}

      # check if $subfield is present

      unless !s_index || s_index == 0
        preceding_index = s_index - 1

        # find preceding field and append a comma if there isn't one there already
        unless name_fields[preceding_index][1][-1] == ","
          name_fields[preceding_index][1] << ","
        end
      end
    end

    # Each part of the name (the a and the b’s) ends in a period, until the name itself is complete, unless there's a subfield after it that takes a different mark of punctuation before it, like an e or it's got term subdivisons like $b LYRASIS $y 21th century.

    ['a', 'b'].each do |subfield|
      s_index = name_fields.find_index {|a| a[0] == subfield}

      # check if $subfield is present

      unless !s_index
        next if (!name_fields[s_index+1].nil? && ['v', 'x', 'y', 'z'].include?(name_fields[s_index+1][0]))
        # find field and append a period if there isn't one there already
        unless ['.', ','].include?(name_fields[s_index][1][-1])
          name_fields[s_index][1] << "."
        end
      end
    end

    apply_terminal_punctuation(name_fields)

    return name_fields
  end

  def gather_agent_corporate_subfield_mappings(name, role_info, agent, terms=nil)
    subfield_e, subfield_4 = prepare_role_subfields(role_info)
    primary_name = name['primary_name'] rescue nil
    sub_name1    = name['subordinate_name_1'] rescue nil
    sub_name2    = name['subordinate_name_2'] rescue nil
    number       = name['number'] rescue nil
    qualifier    = name['qualifier'] rescue nil

    # 610s subfield b is repeatable and SubordinateName1 and SubordinateName2 should be separate subfield b’s

    # Not particularly elegant, but seems to catch all the possibilities
    if sub_name1.nil? || (sub_name1.nil? && sub_name2.nil?)
      subfield_b_1 = nil
      subfield_b_2 = nil
    elsif !sub_name1.nil? && sub_name2.nil?
      subfield_b_1 = sub_name1
      subfield_b_2 = nil
    elsif sub_name1.nil? && !sub_name2.nil?
      subfield_b_1 = sub_name2
      subfield_b_2 = nil
    else
      subfield_b_1 = sub_name1
      subfield_b_2 = sub_name2
    end

    primary_identifier = get_primary_agent_record_identifier(agent) || find_authority_id(agent['names'])

    name_fields = [
                    ['a', primary_name],
                    ['b', subfield_b_1],
                    ['b', subfield_b_2],
                    subfield_e,
                    ['n', number],
                    ['g', qualifier],
                  ].compact.reject {|a| a[1].nil? || a[1].empty?}

    unless terms.nil?
      name_fields.concat handle_agent_terms(terms)
    end

    name_fields = handle_agent_corporate_punctuation(name_fields)

    name_fields.push(['0', primary_identifier]) unless primary_identifier.nil?
    name_fields.push(subfield_4) unless subfield_4.nil?

    return name_fields
  end

end
