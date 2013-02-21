ASpaceExport::model :mods do
  
  include JSONModel

  attr_accessor :title
  attr_accessor :language_term
  attr_accessor :extents
  attr_accessor :notes
  attr_accessor :subjects
  attr_accessor :names
  attr_accessor :type_of_resource
  attr_accessor :parts
  
  
  @archival_object_map = {
    :title => :title=,
    :language => :language_term=,
    :extent => :handle_extent,
    :subjects => :handle_subjects,
    :linked_agents => :handle_agents

  }
  
  @digital_object_map = {
    :notes => :handle_notes
  }

  def initialize
    @extents = []
    @notes = []
    @subjects = []
    @names = []
    @parts = []
  end
    

  # meaning, 'archival object' in the abstract
  def self.from_archival_object(obj)
    
    mods = self.new
    
    mods.apply_map(obj, @archival_object_map)
    
    mods.apply_mapped_relationships(obj, @archival_object_map)
     
    mods
  end
    
  
  def self.from_digital_object(obj)
    
    mods = self.from_archival_object(obj)
    
    mods.type_of_resource = obj.digital_object_type
    
    mods.apply_map(obj, @digital_object_map)
    
    obj.tree['children'].each do |child|
      mods.parts << {'id' => child['id'], 'title' => child['title']}
    end
  
    mods
  end
  
  
  def apply_mapped_relationships(obj, map)  
    obj.class.instance_variable_get(:@relationships).each do |rel|
      Log.debug("--- #{rel[:json_property]}")
      next unless map.has_key?(rel[:json_property].to_sym)
      Log.debug("+++ #{map[rel[:json_property]]}")
      self.send(map[rel[:json_property].to_sym], obj.my_relationships(rel[:name]))
    end
  end
  
  
  def apply_map(obj, map)
    map.each do |as_field, handler|
      self.send(handler, obj.send(as_field)) if obj.respond_to?(as_field)
    end
  end
  
  
  def handle_notes(notes)
    notes = ASUtils.json_parse(DB.deblob(notes) || "[]")
    notes.each do |note|
     self.notes << note
    end 
  end
  
  def handle_extent(extents)
    extents.each do |ext|
      e = ext.number
      e << " (#{ext.portion})" if ext.portion
      e << " #{ext.extent_type}"

      self.extents << e
    end
  end
  
  def handle_subjects(subjects)
    subjects.each do |subject|
      json = subject[1].class.to_jsonmodel(subject[1])
      self.subjects << {'terms' => json.terms.map {|t| t['term']}}
    end
  end
  
  def handle_agents(linked_agents)
    linked_agents.each do |linked_agent|
      json = linked_agent[1].class.to_jsonmodel(linked_agent[1])
      role = linked_agent[0]['role']
      # shift in granularity - role repeats for each name
      json.names.each do |name|
        self.names << {'role' => role, 'parts' => name_parts(name, json.jsonmodel_type)}
      end
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

    fields.map {|field| {'type' => field, 'content' => name[field]}}
    
  end
    
  
  
end
