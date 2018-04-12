class METSModel < ASpaceExport::ExportModel
  model_for :mets
  
  include JSONModel

  attr_accessor :header_agent_name
  attr_accessor :header_agent_notes
  attr_accessor :header_agent_role
  attr_accessor :header_agent_type

  attr_accessor :mods_model
  attr_accessor :dc_model
  attr_accessor :wrapped_dmd
  
  attr_accessor :extents
  attr_accessor :notes
  attr_accessor :subjects
  attr_accessor :names
  attr_accessor :type_of_resource
  attr_accessor :parts
  attr_accessor :dmd_id


  @repository_map = {
    :name => :header_agent_name=,
    :url => :add_agent_note,
  }
  
  @archival_object_map = {
  }
  
  @digital_object_map = {
    :id => :dmd_id=
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
    attr_accessor :mods_model
    attr_accessor :dc_model
    attr_accessor :dmd_id
    
    def initialize(tree)
      resolve = ['linked_agents', 'subjects', 'repository', 'repository::agent_representation']
      obj = URIResolver.resolve_references(DigitalObjectComponent.to_jsonmodel(tree['id']),
                                           resolve)
      @json = JSONModel::JSONModel(:digital_object_component).new(obj)
      @tree = tree
      @mods_model = ASpaceExport.model(:mods).from_digital_object_component(obj, {})
      @dc_model = ASpaceExport.model(:dc).from_digital_object(obj)
      @dmd_id = @json.id
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


  @file_group = Class.new do

    @file_wrapper = Struct.new(:id, :group_id, :uri)

    def self.file_wrapper
      @file_wrapper
    end

    def initialize(use_statement, file_versions)
      @use_statement = use_statement
      @file_versions = file_versions
    end

    def use
      I18n.t("enumerations.file_version_use_statement.#{@use_statement}")
    end

    def with_files
      @file_versions.each do |file|
        id = file['identifier']
        group_id = file['digital_object_id'] || file['digital_object_component_id']
        yield self.class.file_wrapper.new(id, group_id, file['file_uri'])  
      end
    end
  end


  def initialize(obj, tree)
    @json = obj
    @tree = tree
    @wrapped_dmd = []    
    @extents = []
    @notes = []
    @subjects = []
    @names = []
    @parts = []
  end


  def self.get_file_group(*args)
    @file_group.new(*args)
  end


  def self.from_aspace_object(obj, tree)
  
    mets = self.new(obj, tree)
    
    if obj.respond_to?(:repo_id)
      repo_id = RequestContext.get(:repo_id)
      mets.apply_map(Repository.get_or_die(repo_id), @repository_map)
      mets.header_agent_role = "CREATOR"
      mets.header_agent_type = "ORGANIZATION"
    end

    mets.add_agent_note("Produced by ArchivesSpace")

    mets
  end


  def self.from_archival_object(obj, tree)

    mets = self.from_aspace_object(obj, tree)
    mets.apply_map(obj, @archival_object_map)
    mets
  end

  
  def self.from_digital_object(obj, tree)

    mets = self.from_archival_object(obj, tree)
    mets.type_of_resource = obj.digital_object_type
    mets.apply_map(obj, @digital_object_map)

    # wrapped DMD
    mets.mods_model = ASpaceExport.model(:mods).from_digital_object(obj, :ignore => [:tree])
    mets.dc_model = ASpaceExport.model(:dc).from_digital_object(obj)
    mets
  end

  
  def self.name_type_map
    @name_type_map
  end


  def self.name_part_type_map
    @name_part_type_map
  end


  def add_agent_note(val)
    @header_agent_notes ||= []
    @header_agent_notes << val
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
    return nil unless @tree['children']
    
    ao_class = self.class.instance_variable_get(:@doc)
    
    children = @tree['children'].map { |subtree| ao_class.new(subtree) }
    
    children
  end


  def with_file_groups
    file_versions = @json.file_versions
    file_versions.each do |fv|
      fv['digital_object_id'] = @json.id
    end
    file_versions += extract_file_versions(@tree['children'])
    file_versions.compact!

    while file_versions.length > 0
      use_statement = file_versions[0]['use_statement']
      use_group = file_versions.select {|fv| fv['use_statement'] == use_statement }
      yield self.class.get_file_group(use_statement, use_group)

      file_versions.reject! {|fv| fv['use_statement'] == use_statement }
    end
  end

  @@logical_div = Struct.new(:label,
                             :dmdid, 
                             :file_versions, 
                             :children) do

    def self.init
      @order = 0
    end

    def self.next_order
      @order += 1
      @order
    end

    def order
      @order ||= self.class.next_order
      @order
    end

    def has_files?
      file_versions.count > 0
    end

    def each_file_version
      file_versions.each do |file|
        yield Struct.new(:id).new(file['identifier'])
      end
    end

    def each_child
      children.each do |child|
        yield self.class.new(child['title'],
                             child['id'],
                             child['file_versions'],
                             child['children'])
      end
    end
  end


  def root_logical_div
    @@logical_div.init
    @@logical_div.new(@json.title,
                      @json.id, 
                      @json.file_versions,
                      @tree['children'])

  end


  def root_physical_div
    @@logical_div.init
    @@logical_div.new(@json.title,
                      @json.id, 
                      @json.file_versions,
                      @tree['children'])

  end  


  def extract_file_versions(children)
    file_versions = []

    children.each do |child|
      if child['file_versions']
        file_versions += child['file_versions']
      end
      if child['children']
        file_versions += extract_file_versions(child['children'])
      end
    end

    file_versions
  end

end
