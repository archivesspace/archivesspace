ASpaceExport::model :mets do
  
  include JSONModel

  attr_accessor :header_agent_name
  attr_accessor :header_agent_note
  attr_accessor :header_agent_role
  attr_accessor :header_agent_type
  
  attr_accessor :wrapped_dmd
  
  attr_accessor :extents
  attr_accessor :notes
  attr_accessor :subjects
  attr_accessor :names
  attr_accessor :type_of_resource
  attr_accessor :parts
  
  @repository_map = {
    :name => :header_agent_name=,
    :values => :build_header_agent_note,
  }
  
  
  @archival_object_map = {
  }
  
  @digital_object_map = {
  }
  
  
  @name_type_map = {
    'agent_person' => 'personal',
    'agent_family' => 'family',
    'agent_corporate' => 'corporate',
    'agent_software' => nil
  }
  
  @name_part_type_map = {
    'primary_name' => 'family',
    'title' => 'termsOfAddress',
    'rest_of_name' => 'given',
    'family_name' => 'family',
    'prefix' => 'termsOfAddress'
  }
  
  @doc = Class.new do
    
    def initialize(tree)
      obj = DigitalObjectComponent.to_jsonmodel(tree['id'])
      @json = JSONModel::JSONModel(:digital_object_component).new(obj)
      @tree = tree
    end
    
    def method_missing(meth)
      if @json.respond_to?(meth)
        @json.send(meth)
      else
        nil
      end
    end
    
    def children
      return nil unless @tree['children']
      @tree['children'].map { |subtree| self.class.new(subtree) }
    end
  end
  

  def initialize(obj)
    @json = obj
    @wrapped_dmd = []
    
    @extents = []
    @notes = []
    @subjects = []
    @names = []
    @parts = []
  end
  
  # Some things are universal
  def self.from_aspace_object(obj)
  
    mets = self.new(obj)
    
    if obj.respond_to?(:repo_id)
      repo_id = RequestContext.get(:repo_id)
      mets.apply_map(Repository.get_or_die(repo_id), @repository_map)
      mets.header_agent_role = "CREATOR"
      mets.header_agent_type = "ORGANIZATION"
    end
    
    mets
  end
    
  # meaning, 'archival object' in the abstract
  def self.from_archival_object(obj)
    
    mets = self.from_aspace_object(obj)
    
    mets.apply_map(obj, @archival_object_map)
         
    mets
  end
    
  
  def self.from_digital_object(obj)
    
    mets = self.from_archival_object(obj)
    
    mets.type_of_resource = obj.digital_object_type
    
    mets.apply_map(obj, @digital_object_map)
    
    # wrapped DMD
    mods = ASpaceExport.model(:mods).from_digital_object(obj)
    mods_callback = lambda {|mods, xml|
                            mods_ns = xml.doc.root.namespace_definitions.find{|ns| ns.prefix == 'mods'}
                            xml.instance_variable_set(:@sticky_ns, mods_ns)
                            ASpaceExport.serializer(:mods)._mods(mods, xml)
                            xml.instance_variable_set(:@sticky_ns, nil)
                             }

    mets.dmd_wrap("MODS", mods_callback, mods)
  
    mets
  end
  
  def self.name_type_map
    @name_type_map
  end
  
  def self.name_part_type_map
    @name_part_type_map
  end
  
  def build_header_agent_note(vals)
    note = String.new
    vals.reject! {|k,v| v.nil?}
    note += "Parent Institution: #{vals[:parent_institution_name]}" if vals[:parent_institution_name]
    self.header_agent_note = note unless note.empty?
  end
  
  def dmd_wrap(mdtype, callback, data)
    self.wrapped_dmd << {'type' => mdtype,'callback' => callback, 'data' => data}
  end
  
  def method_missing(meth)
    if @json.respond_to?(meth)
      @json.send(meth)
    else
      nil
    end
  end
  
  def children
    return nil unless @json.tree['_resolved']['children']
    
    ao_class = self.class.instance_variable_get(:@doc)
    
    children = @json.tree['_resolved']['children'].map { |subtree| ao_class.new(subtree) }
    
    children
  end
  
  
end
