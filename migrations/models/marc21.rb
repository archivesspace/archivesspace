ASpaceExport::model :marc21 do

  include JSONModel

  def self.df_handler(name, tag, ind1, ind2, code)
    define_method(name) do |val|
      df(tag, ind1, ind2).with_sfs([code, val])
    end
    name.to_sym
  end

  @archival_object_map = {
    :repository => :handle_repo_code,
    :title => :handle_title,
    :linked_agents => :handle_agents,
    :subjects => :handle_subjects,
    :extents => :handle_extents,
    :language => df_handler('lang', '041', '0', ' ', 'a'),
    :dates => :handle_dates,
  }

  @resource_map = {
    [:id_0, :id_1, :id_2, :id_3] => :handle_id,
    :notes => :handle_notes,
    :finding_aid_description_rules => df_handler('fadr', '040', ' ', ' ', 'e'),
    :ead_location => :handle_ead_loc
  }

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

  def initialize
    @datafields = {}
  end

  def datafields
    @datafields.map {|k,v| v}
  end


  def self.from_aspace_object(obj)
    self.new
  end

  # 'archival object's in the abstract
  def self.from_archival_object(obj)

    marc = self.from_aspace_object(obj)

    marc.apply_map(obj, @archival_object_map)

    marc
  end

  # subtypes of 'archival object':

  def self.from_resource(obj)
    marc = self.from_archival_object(obj)
    marc.apply_map(obj, @resource_map)
    marc.leader_string = "00000np$ a2200000 u 4500"
    marc.leader_string[7] = obj.level == 'item' ? 'm' : 'c'

    marc.controlfield_string = assemble_controlfield_string(obj)

    marc
  end


  def self.assemble_controlfield_string(obj)
    date = obj.dates[0] || {}
    string = obj['system_mtime'].scan(/\d{2}/)[1..3].join('')
    string += obj.level == 'item' && date['date_type'] == 'single' ? 's' : 'i'
    string += date['begin'] ? date['begin'][0..3] : "    "
    string += date['end'] ? date['end'][0..3] : "    "
    string += "xx"
    18.times { string += ' ' }
    string += obj.language
    string += ' d'

    string
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
    ids.reject!{|i| i.nil? || i.empty?}
    df('099', ' ', ' ').with_sfs(['a', ids.join('.')])
    df('852', ' ', ' ').with_sfs(['c', ids.join('.')])
  end


  def handle_title(title)
    df('245', '1', '0').with_sfs(['a', title])
  end

  def handle_dates(dates)
    d0 = dates[0]
    return false unless d0

    code = d0['date_type'] == 'bulk' ? 'g' : 'f'
    val = nil
    if d0['expression']
      val = d0['expression']
    elsif d0['date_type'] == 'single'
      val = d0['begin']
    elsif d0['date_type'] == 'inclusive'
      val = "#{d0['begin']} - #{d0['end']}"
    end

    df('245', '1', '0').with_sfs([code, val])
  end

  def handle_repo_code(repository)
    repo = repository['_resolved']
    return false unless repo
    
    df('852', ' ', ' ').with_sfs(
                        ['a', "Repository: #{repo['repo_code']}"],
                        ['a', repo['org_code']],
                        ['b', repo['name']]
                      )
    df('040', ' ', ' ').with_sfs(['a', repo['org_code']], ['c', repo['org_code']])
  end

  def source_to_code(source)
    ASpaceMappings::MARC21.get_marc_source_code(source)
  end

  def handle_subjects(subjects)
    subjects.each do |link|
      subject = link['_resolved']
      term = subject['terms'][0]
      terms = subject['terms'][1..-1]
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
                    end
      sfs = [['a', term['term']]]

      if ind2 == '7'
        sfs << ['2', subject['source']]
      end

      terms.each do |t|
        tag = case t['term_type']
              when 'genre_form', 'style_period'; 'v'
              when 'topical', 'cultural_context'; 'x'
              when 'temporal', 'y'
              when 'geographic', 'z'
              end
        sfs << [(tag), t['term']]
      end

      df(code, ' ', ind2).with_sfs(*sfs)
    end
  end


  def handle_primary_creator(linked_agents)
    link = linked_agents.find{|a| a['role'] == 'creator'}
    return nil unless link

    creator = link['_resolved']
    name = creator['names'][0]

    role_info = link['relator'] ? ['4', link['relator']] : ['e', 'creator']

    case creator['agent_type']

    when 'agent_corporate_entity'
      df('110', '2', ' ').with_sfs(
                                  ['a', name['primary_name']],
                                  ['b', name['subordinate_name_1']],
                                  ['b', name['subordinate_name_2']],
                                  ['n', name['number']],
                                  ['d', name['dates']],
                                  ['g', name['qualifier']],
                                  role_info
                                  )
    when 'agent_person'
      joint, ind1 = name['name_order'] == 'direct' ? [' ', '0'] : [', ', '1']
      name_parts = [name['primary_name'], name['rest_of_name']].reject{|i| i.nil? || i.empty?}.join(joint)

      df('100', ind1, ' ').with_sfs(
                                  ['a', name_parts],
                                  ['b', name['number']],
                                  ['c', %w(prefix, title, suffix).map {|prt| name[prt]}.join(', ')],
                                  ['q', name['fuller_form']],
                                  ['d', name['dates']],
                                  ['g', name['qualifier']],
                                  role_info
                                  )

    when 'agent_family'
      df('100', '3', ' ').with_sfs(
                                  ['a', name['family_name']],
                                  ['c', name['prefix']],
                                  ['d', name['dates']],
                                  ['g', name['qualifier']],
                                  role_info
                                  )

    end
  end


  def handle_agents(linked_agents)

    handle_primary_creator(linked_agents)

    subjects = linked_agents.select{|a| a['role'] == 'subject'}

    subjects.each do |link|
      subject = link['_resolved']
      name = subject['names'][0]
      relator = link['relator']
      terms = link['terms']
      ind2 = source_to_code(subject['source'])

      case subject['agent_type']

      when 'agent_corporate_entity'
        df('610', '2', ind2).with_sfs(
                                          ['a', name['primary_name']],
                                          ['b', name['subordinate_name_1']],
                                          ['b', name['subordinate_name_2']],
                                          ['n', name['number']],
                                          ['g', name['qualifier']],
                                          )
      when 'agent_person'
        joint, ind1 = name['name_order'] == 'direct' ? [' ', '0'] : [', ', '1']
        name_parts = [name['primary_name'], name['rest_of_name']].reject{|i| i.nil? || i.empty?}.join(joint)
        ind1 = name['name_order'] == 'direct' ? '0' : '1'

        df('600', ind1, ind2).with_sfs(
                                          ['a', name_parts],
                                          ['b', name['number']],
                                          ['c', %w(prefix title suffix).map {|prt| name[prt]}.compact.join(', ')],
                                          ['q', name['fuller_form']],
                                          ['d', name['dates']],
                                          ['g', name['qualifier']],
                                          )

      when 'agent_family'
        df('600', '3', ind2).with_sfs(
                                          ['a', name['family_name']],
                                          ['c', name['prefix']],
                                          ['d', name['dates']],
                                          ['g', name['qualifier']],
                                          )

      end
    end


    creators = linked_agents.select{|a| a['role'] == 'creator'}[1..-1] || []
    creators = creators + linked_agents.select{|a| a['role'] == 'source'}

    creators.each do |link|
      creator = link['_resolved']
      name = creator['names'][0]
      relator = link['relator']
      terms = link['terms']
      role = link['role']

      if relator
        relator_sf = ['4', relator]
      elsif role == 'source'
        relator_sf =  ['e', 'former owner']
      else
        relator_sf = ['e', 'creator']
      end

      case creator['agent_type']

      when 'agent_corporate_entity'
        df('710', '2', ' ').with_sfs(
                                          ['a', name['primary_name']],
                                          ['b', name['subordinate_name_1']],
                                          ['b', name['subordinate_name_2']],
                                          ['n', name['number']],
                                          ['g', name['qualifier']],
                                          relator_sf
                                          )
      when 'agent_person'
        joint, ind1 = name['name_order'] == 'direct' ? [' ', '0'] : [', ', '1']
        name_parts = [name['primary_name'], name['rest_of_name']].reject{|i| i.nil? || i.empty?}.join(joint)
        ind1 = name['name_order'] == 'direct' ? '0' : '1'

        df('700', ind1, ' ').with_sfs(
                                          ['a', name_parts],
                                          ['b', name['number']],
                                          ['c', %w(prefix title suffix).map {|prt| name[prt]}.compact.join(', ')],
                                          ['q', name['fuller_form']],
                                          ['d', name['dates']],
                                          ['g', name['qualifier']],
                                          relator_sf
                                          )

      when 'agent_family'
        df('700', '3', ' ').with_sfs(
                                          ['a', name['family_name']],
                                          ['c', name['prefix']],
                                          ['d', name['dates']],
                                          ['g', name['qualifier']],
                                          relator_sf
                                          )
      end
    end

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
                    ['351','b']
                  when 'fileplan'
                    ['351', 'b']
                  when 'odd', 'dimensions', 'physdesc', 'materialspec', 'physloc', 'phystech', 'physfacet', 'processinfo', 'separatedmaterial'
                    ['500','a']
                  when 'accessrestrict'
                    ['506','a']
                  when 'scopecontent', 'abstract'
                    ['520', '1', '3', 'a']
                  when 'prefercite'
                    ['534', '8', ' ', 'a']
                  when 'acqinfo'
                    ind1 = note['publish'] ? '0' : '1'
                    ['541', ind1, ' ', 'a']
                  when 'relatedmaterial'
                    ['544','a']
                  when 'bioghist'
                    ['545','a']
                  when 'custodhist'
                    ind1 = note['publish'] ? '0' : '1'
                    ['561', ind1, ' ', 'a']
                  when 'appraisal'
                    ind1 = note['publish'] ? '0' : '1'
                    ['583', ind1, ' ', 'a']
                  when 'accruals'
                    ['584', 'a']
                  when 'altformavail', 'originalsloc'
                    ['535', '2', '1', 'a']
                  when 'userestrict', 'legalstatus'
                    ['540', 'a']
                  when 'langmaterial'
                    ['546', 'a']
                  else
                    nil
                  end

      unless marc_args.nil?
        text = prefix ? "#{prefix}: " : ""
        text += ASpaceExport::Utils.extract_note_text(note)
        df(*marc_args[0...-1]).with_sfs([marc_args.last, *Array(text)])
      end

    end
  end


  def handle_extents(extents)
    extents.each do |ext|
      e = ext['number']
      # e << " (#{ext['portion']})" if ext['portion']
      e << " #{I18n.t('enumerations.extent_extent_type.'+ext['extent_type'])}"
      df('300').with_sfs(['a', e])
    end
  end


  def handle_ead_loc(ead_loc)
    df('555', ' ', ' ').with_sfs(['a', ead_loc], ['u', 'ead_location'])
    df('856', '4', '2').with_sfs(
                                  ['z', "Finding aid online:"],
                                  ['u', ead_loc]
                                )
  end

end
