ASpaceExport::model :ead do
  
  @ao = Class.new do
    
    def initialize(tree)
      obj = ArchivalObject.to_jsonmodel(tree['id'])
      @json = JSONModel::JSONModel(:archival_object).new(obj)
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
  end
  

  def self.from_aspace_object(obj)
  
    ead = self.new(obj)
    
    # if obj.class.model_scope == :repository
    #   ead.apply_map(Repository.get_or_die(obj.repo_id), @repository_map)
    # end
    
    ead
  end
    
  
  def self.from_resource(obj)
    ead = self.from_aspace_object(obj)
    
    # ead.instance_variable_set(:@tree, tree)
    
    ead
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
    
    ao_class = self.class.instance_variable_get(:@ao)
    
    children = @json.tree['_resolved']['children'].map { |subtree| ao_class.new(subtree) }
    
    children
  end
  
end
