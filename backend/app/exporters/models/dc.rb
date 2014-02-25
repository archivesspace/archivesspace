class DCModel < ASpaceExport::ExportModel
  model_for :dc

  include JSONModel

  attr_accessor :title
  attr_accessor :identifier
  attr_accessor :creators
  attr_accessor :subjects
  attr_accessor :sources
  attr_accessor :dates
  attr_accessor :type
  attr_accessor :language
  attr_accessor :rights
  
  
  @archival_object_map = {
    :title => :title=,
    :date => :handle_date,
    :language => :language=,
    :rights_statement => :handle_rights,
    :linked_agents => :handle_agents,
    :subjects => :handle_subjects
  }
  
  @digital_object_map = {}
  
  
  def initialize
    @creators = []
    @subjects = []
    @sources = []
    @dates = []
    @rights = []
  end
  
  # Some things are universal
  def self.from_aspace_object(obj)
  
    dc = self.new
    
    dc
  end
    
  # meaning, 'archival object' in the abstract
  def self.from_archival_object(obj)
    
    dc = self.from_aspace_object(obj)
    
    dc.apply_map(obj, @archival_object_map)
    
    dc
  end
    
  
  def self.from_digital_object(obj)
    
    dc = self.from_archival_object(obj)
    
    dc.apply_map(obj, @digital_object_map)

    dc.identifier = "#{AppConfig[:backend_url]}#{obj.uri}"

    dc.type = obj.digital_object_type
  
    dc
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
      # false friend: http://dublincore.org/documents/2012/06/14/dcmi-terms/?v=elements#terms-source
      # when 'source'
      #   json.names.each {|n| self.sources << n['sort_name'] }
      end
    end
  end
  
  
  def handle_date(dates)
    dates.each do |date|
      d = if date['expression']
            date['expression']
          elsif date['begin'] && date['end']
            "#{date['begin']} - #{date['end']}" 
          elsif date['begin']
            date['begin']
          elsif date['end']
            date['end']
          else
            "unknown"
          end
      self.dates << d
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
