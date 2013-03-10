ASpaceExport::model :eac do
  
  @eac_event = Class.new do
    
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
      d = @event.date['begin']
      if @event.date['begin_time']
        d << "T#{@event.date['begin_time']}"
      end
      
      d
    end
    
    def agents
      @event.linked_agents.map {|a| ['human', a['_resolved']['name']] }
    end  

  end
   

  def initialize(obj, events)
    @json = obj
    @events = events.map {|e| self.class.instance_variable_get(:@eac_event).new(e) }
  end
  
  def self.from_aspace_object(obj, events)
  
    self.new(obj, events)
  end
    
  
  def self.from_agent(obj, events = [])
    eac = self.from_aspace_object(obj, events)
  
    eac
  end
  
  
  def events
    @events
  end
  
  
  def method_missing(meth)
    if @json.respond_to?(meth)
      @json.send(meth)
    else
      nil
    end
  end
  
  
end
