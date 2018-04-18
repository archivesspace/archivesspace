class DCModel < ASpaceExport::ExportModel
  model_for :dc

  include JSONModel

  attr_accessor :title
  attr_accessor :identifier
  attr_accessor :creators
  attr_accessor :subjects
  attr_accessor :dates
  attr_accessor :type
  attr_accessor :language

  
  
  @archival_object_map = {
    :title => :title=,
    :dates => :handle_date,
    :language => :language=,
    :linked_agents => :handle_agents,
    :subjects => :handle_subjects
  }
  
  @digital_object_map = {}
  
  
  def initialize(obj)
    @creators = []
    @subjects = []
    @sources = []
    @dates = []
    @rights = []
    @json = obj
  end


  def self.from_archival_object(obj)
    
    dc = self.new(obj)
    
    dc.apply_map(obj, @archival_object_map)
    
    dc
  end
    
  
  def self.from_digital_object(obj)
    
    dc = self.from_archival_object(obj)
    
    dc.apply_map(obj, @digital_object_map)

    if obj.respond_to?('uri')
      dc.identifier = "#{AppConfig[:backend_url]}#{obj.uri}"
    end

    if obj.respond_to?('digital_object_type')
      dc.type = obj.digital_object_type
    end
  
    dc
  end

  def self.DESCRIPTIVE_NOTE_TYPES
    @descriptive_note_type ||= %w(bioghist prefercite)
    @descriptive_note_type
  end

  def self.RIGHTS_NOTE_TYPES
    @rights_note_type ||= %w(accessrestrict userestrict)
    @rights_note_type
  end

  def self.FORMAT_NOTE_TYPES
    @format_note_type ||= %w(dimensions physdesc)
    @format_note_type
  end

  def self.SOURCE_NOTE_TYPES
    @source_note_type ||= %w(originalsloc)
    @source_note_type
  end

  def self.RELATION_NOTE_TYPES
    @relation_note_type ||= %w(relatedmaterial)
    @relation_note_type
  end

  def each_description
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        if self.class.DESCRIPTIVE_NOTE_TYPES.include? note['type']
          yield extract_note_content(note)
        end
      end

      repo = @json.repository['_resolved']
      repo_info = "Digital object made available by #{repo['name']}"
      repo_info << " (#{repo['url']})" if repo['url']

      yield repo_info
    end
  end

  def each_rights
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        if self.class.RIGHTS_NOTE_TYPES.include? note['type']
          yield extract_note_content(note)
        end
      end
    end
  end

  def each_format
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        if self.class.FORMAT_NOTE_TYPES.include? note['type']
          yield extract_note_content(note)
        end
      end
    end
  end

  def each_source
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        if self.class.SOURCE_NOTE_TYPES.include? note['type']
          yield extract_note_content(note)
        end
      end
    end
  end

  def each_relation
    if @json.respond_to?('notes')
      @json.notes.each do |note|
        if self.class.RELATION_NOTE_TYPES.include? note['type']
          yield extract_note_content(note)
        end
      end
    end
  end


  def handle_agents(linked_agents)
    linked_agents.each do |link|

      role = link['role']
      agent = link['_resolved']

      case role
      when 'creator'        
        agent['names'].each {|n| self.creators << n['sort_name'] }
      when 'subject'
        agent['names'].each {|n| self.subjects << n['sort_name'] }
      end
    end
  end
  
  
  def handle_date(dates)
    dates.each do |date|
      self.dates << extract_date_string(date)
    end
  end
  
  
  def handle_rights(rights_statements)
    rights_statements.each do |rs|
      
      case rs['rights_type']
      
      when 'license'
        self['rights'] << "License: #{rs.license_identifier_terms}"
      end
      
      if rs['permissions']
        self['rights'] << "Permissions: #{rs.permissions}"
      end
      
      if rs['restrictions']
        self['rights'] << "Restriction: #{rs.restrictions}"
      end
    end  
  end    
        
  def handle_subjects(subjects)
    subjects.map {|s| s['_resolved'] }.each do |subject|
      self.subjects << subject['terms'].map {|t| t['term'] }.join('--')
    end
  end
  
end
