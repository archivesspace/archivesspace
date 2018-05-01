class MODSModel < ASpaceExport::ExportModel
  model_for :mods

  include JSONModel

  attr_accessor :title
  attr_accessor :language_term
  attr_accessor :extents
  attr_accessor :notes
  attr_accessor :extent_notes
  attr_accessor :subjects
  attr_accessor :names
  attr_accessor :type_of_resource
  attr_accessor :parts
  attr_accessor :repository_note
  attr_accessor :identifier
  attr_accessor :dates

  @archival_object_map = {
    :title => :title=,
    :language => :handle_language,
    [:extents, :notes] => :handle_extents,
    :subjects => :handle_subjects,
    :linked_agents => :handle_agents,
    :notes => :handle_notes,
    :digital_object_id => :handle_id,
    :dates => :handle_dates
  }

  @digital_object_map = {
  }


  @name_type_map = {
    'agent_person' => 'personal',
    'agent_family' => 'family',
    'agent_corporate_entity' => 'corporate',
    'agent_software' => nil
  }

  @name_part_type_map = {
    'primary_name' => 'family',
    'title' => 'termsOfAddress',
    'rest_of_name' => 'given',
    'family_name' => 'family',
    'prefix' => 'termsOfAddress'
  }


  def initialize(tree)
    @children = tree['children']

    @extents = []
    @notes = []
    @extent_notes = []
    @subjects = []
    @names = []
    @parts = []
    @dates = []
  end


  # meaning, 'archival object' in the abstract
  def self.from_archival_object(obj, tree)

    mods = self.new(tree)
    mods.apply_map(obj, @archival_object_map)

    mods
  end


  def self.from_digital_object(obj, tree, opts = {})
    mods = self.from_archival_object(obj, tree)

    if obj.respond_to? :digital_object_type
      unless obj.digital_object_type.nil? || obj.digital_object_type.empty?
        mods.type_of_resource = I18n.t("enumerations.digital_object_digital_object_type." + obj.digital_object_type)
      else
        mods.type_of_resource = nil
      end
    end

    mods.apply_map(obj, @digital_object_map, opts)

    mods.repository_note = build_repo_note(obj.repository['_resolved'])

    mods
  end


  def self.from_digital_object_component(obj, tree)
    mods = self.from_archival_object(obj, tree)

    mods
  end


  def self.name_type_map
    @name_type_map
  end

  def self.name_part_type_map
    @name_part_type_map
  end

  @@mods_note = Struct.new(:tag, :type, :label, :content, :wrapping_tag)
  def self.new_mods_note(*a)
    @@mods_note.new(*a)
  end


  def self.build_repo_note(repo_record)
    agent = repo_record['agent_representation']['_resolved']
    contacts = agent['agent_contacts']

    contents = [repo_record['name']]
    if contacts.length > 0
      contents += %w(address_1 address_2 address_3 city region post_code country).map {|part|
        contacts[0][part] }.compact
    end

    contents = contents.join(', ')
    if repo_record['url']
      contents << " (#{repo_record['url']})"
    end

    new_mods_note('note', nil, "Digital object made available by", contents)
  end


  def new_mods_note(*a)
    self.class.new_mods_note(*a)
  end


  def handle_notes(notes)
    notes.each do |note|
      # physdesc and dimensions are treated separately from other notes
      next if note['type'] == 'physdesc' || note['type'] == 'dimensions'
      content = ASpaceExport::Utils.extract_note_text(note)
      mods_note = case note['type']
                  when 'accessrestrict'
                    new_mods_note('accessCondition',
                                   'restrictionOnAccess',
                                   note['label'],
                                   content)
                  when 'userestrict'
                    new_mods_note('accessCondition',
                                  'useAndReproduction',
                                  note['label'],
                                  content)
                  when 'legalstatus'
                    new_mods_note('accessCondition',
                                  note['type'],
                                  note['label'],
                                  content)
                  else
                    new_mods_note('note',
                                  note['type'],
                                  note['label'],
                                  content)
                  end
     self.notes << mods_note
    end
  end

  # notes relating to extents are treated differently than other notes 
  # when the model is serialized.
  def handle_extents_notes(notes)
    notes.each do |note|
      next unless note['type'] == 'physdesc' || note['type'] == 'dimensions'
      next unless note['publish'] == true

      content = ASpaceExport::Utils.extract_note_text(note)
      mods_note = case note['type']
                  when 'physdesc'
                    new_mods_note('note',
                                  'physical_description',
                                  "Physical Details",
                                  content)
                  when 'dimensions'
                    new_mods_note('note',
                                  'dimensions',
                                  "Dimensions",
                                  content)
                  end
      self.extent_notes << mods_note
    end
  end


  def handle_extents(extents, notes)
    extents.each do |ext|
      e = ext['number']
      e << " #{ext['extent_type']}"

      self.extents << e

      # the extents hash may have data under keys 'physical_details' and 'dimensions'.
      # If found, we'll treat them as if they were notes of that type.
      if ext.has_key?('physical_details') && !ext['physical_details'].nil?
        extent_notes << new_mods_note('note', 'physical_description', "Physical Details", ext['physical_details'])
      end
        
      if ext.has_key?('dimensions') && !ext['dimensions'].nil?
        extent_notes << new_mods_note('note', 'dimensions', "Dimensions", ext['dimensions'])
      end
    end

    # process any physical_description and dimension notes that may be in the note list.
    handle_extents_notes(notes)
  end


  def handle_subjects(subjects)
    subjects.map {|s| s['_resolved'] }.each do |subject|
      self.subjects << {
        'term' => subject['terms'].map {|t| t['term']},
        'source' => subject['source'],
        'term_type' => subject['terms'].map {|t| t['term_type']}
      }
    end
  end


  def handle_agents(linked_agents)
    linked_agents.each do |link|
      agent = link['_resolved']
      role = link['role']
      name_type = self.class.name_type_map[agent['jsonmodel_type']]
      # shift in granularity - role repeats for each name
      agent['names'].each do |name|
        self.names << {
          'type' => name_type,
          'role' => role,
          'source' => name['source'],
          'authority_id' => name['authority_id'],
          'parts' => name_parts(name, agent['jsonmodel_type']),
          'displayForm' => name['sort_name']
        }
      end
    end
  end

  def handle_id(digital_object_id)
    self.identifier = digital_object_id
  end


  def handle_dates(dates)
    dates.each do |date|
      self.dates.push date
    end
  end


  def handle_language(language_term)
      unless language_term.nil? || language_term.empty?
        self.language_term = I18n.t("enumerations.language_iso639_2." + language_term) + ":" + language_term
      else
        self.language_term = nil
      end
  end


  def name_parts(name, type)
    fields = case type
             when 'agent_person'
               ["primary_name", "title", "prefix", "rest_of_name", "suffix", "fuller_form", "number"]
             when 'agent_family'
               ["family_name", "prefix"]
             when 'agent_software'
               ["software_name", "version", "manufacturer"]
             when 'agent_corporate_entity'
               ["primary_name", "subordinate_name_1", "subordinate_name_2", "number"]
             end
    parts = []
    fields.each do |field|
      part = {}
      part['type'] = self.class.name_part_type_map[field]
      part.delete('type') if part['type'].nil?
      part['content'] = name[field] unless name[field].nil?
      parts << part unless part.empty?
    end
    parts
  end

  def each_related_item(children = nil, maxDepth = 20)
    return if maxDepth == 0
    maxDepth = maxDepth - 1
    children ||= @children

    return unless children
    children.each do |child|
      json = JSONModel(:digital_object_component).new(child)
      yield self.class.from_digital_object_component(json, child)
      if child['children']
        each_related_item(child['children'], maxDepth) do |item|
          yield item
        end
      end
    end
  end

end
