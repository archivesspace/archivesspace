class MARCAuthModel < ASpaceExport::ExportModel
  model_for :marc_auth

  attr_reader :related_records, :json

  RESOLVE = ['subjects', 'places']

  
  @marc_auth_event = Class.new do
    
    def initialize(event)
      @event = event
    end
    
    def method_missing(meth)
      if @event.respond_to?(meth)
        @event.send(meth)
      else
        nil
      end
    end
    
    def type
      if @event.event_type == 'cataloging'
        'created'
      else
        @event.event_type
      end
    end
    
    def date_time
      @date_time ||= nil

      if @date_time.nil?
        if @event.date
          @date_time = @event.date['begin']
        else
          @date_time = @event.timestamp.gsub(/Z.*/, '')
        end
      end
      
      @date_time
    end
    
    def agents
      
      agents = []
      
      @event.linked_agents.each do |a| 
        case a['_resolved']['agent_type']
        when 'agent_person'
          agents << ['human', a['_resolved']['display_name']['sort_name']]
        when 'agent_software'
          agents << ['machine', a['_resolved']['display_name']['sort_name']] 
        end
      end
      
      agents
    end  

  end
   

  def initialize(obj, events, related_records, repo)
    @type = obj.jsonmodel_type
    @json = URIResolver.resolve_references(obj, RESOLVE)
    @events = events.map {|e| self.class.instance_variable_get(:@marc_auth_event).new(e) }
    @related_records = related_records
    @repo = repo
  end
   
  
  def self.from_agent(obj, events, related_records, repo)
    self.new(obj, events, related_records, repo)
  end
  
  
  def events
    @events
  end


  def maintenanceAgency
    if @ma.nil?
      @ma = OpenStruct.new
      @ma.agencyName = @repo.name
      if @repo.org_code
        @ma.agencyCode = @repo.org_code
      end
    end

    @ma
  end
  
  
  def method_missing(meth)
    if @json.respond_to?(meth)
      @json.send(meth)
    else
      nil
    end
  end


  def related_agents
    if @json.respond_to?(:related_agents)
      @json.related_agents
    else
      []
    end
  end


  # maps name.{field} => EAC @localType attribute
  def name_part_fields
    case @type
    when 'agent_person'
      {
        "primary_name" => "surname",
        "title" => "title",
        "prefix" => "prefix",
        "rest_of_name" => "forename",
        "suffix" => "suffix",
        "fuller_form" => "fuller_form",
        "number" => "numeration",
        "qualifier" => "qualifier",
        "dates" => "dates",
      }
    when 'agent_family'
      {
        "prefix" => "prefix",
        "family_name" => 'surname',
        "number" => "numeration",
        "qualifier" => "qualifier",
        "location" => "location",
        "dates" => "dates",
        "family_type" => "family_type",
      }
    # TODO: Remove software?
    when 'agent_software'
      {
        "software_name" => nil,
        "version" => nil,
        "manufacturer" => nil
      }
    when 'agent_corporate_entity'
      {
        "primary_name" => "primary_name", 
        "subordinate_name_1" => "subordinate_name_1", 
        "subordinate_name_2" => "subordinate_name_2", 
        "number" => "numeration",
        "qualifier" => "qualifier",
        "location" => "location",
        "dates" => "dates",
      }
    end
  end

end
