class LabelModel < ASpaceExport::ExportModel
  model_for :labels
  
  @ao = Class.new do
    
    def initialize(tree)
      obj = URIResolver.resolve_references( ArchivalObject.to_jsonmodel(tree['id']),
                                           ['top_container', 'top_container::container_profile',
                                            'top_container::container_locations'])
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
    

  def initialize(obj, tree)
    @json = obj
    @tree = tree

    @rows = generate_label_rows(self.children) 
  end
  
  
  def headers
    %w(
      Repository\ Name Resource\ Title  Resource\ Identifier Series\ Archival\ Object\ Title
      Archival\ Object\ Title Container\ Profile Top\ Container Top\ Container\ Barcode
      SubContainer\ 1 SubContainer\ 2 Current\ Location 
    )
  end
  
 
  # The first 3 cells are pulled from the tip-top AO, with the rest being 
  # added once we pull child AOs, Instance, TC, C.Profile, etc
  def rows
    @rows.map {|r| [self.repo_name, self.title, self.identifier] + r }
  end
  

  def self.from_aspace_object(obj, tree)
    labler = self.new(obj, tree)
    
    labler
  end
    
  
  def self.from_resource(obj, tree)
    labler = self.from_aspace_object(obj, tree)
    
    labler
  end
  
  
  def method_missing(meth)
    if @json.respond_to?(meth)
      @json.send(meth)
    else
      nil
    end
  end
  
  def identifier
    @identifier ||= [:id_0, :id_1, :id_2, :id_3].map {|i| self.send(i) }.reject {|i| i.nil? }.join("-")
    
    @identifier
  end
  
  
  def repo_name
    if self.repository && self.repository.has_key?('_resolved')
      self.repository['_resolved']['name']
    else
      "Unknown"
    end
  end
  
  
  def children
    return nil unless @tree.children

    ao_class = self.class.instance_variable_get(:@ao)

    @tree.children.map { |subtree| ao_class.new(subtree) }
  end
 
  # this is a convenience method to either return either the value from a hash
  # from an array of keys or a blank string ( if it does not exist ) 
  def value_or_blank(hash, keys = [] )
    keys.reduce(hash) do |memo, k|
      if memo.is_a?(Hash) && memo[k]
        memo[k]
      else
        ""
      end
    end
  end

  def generate_label_rows(objects)
    @top_containers ||= []
    @series ||= ""
    rows = []
    
    objects.each do |obj|
      @series = obj.display_string if obj.level == 'series' 
      obj.instances.each do |instance|
        next unless (sub = instance['sub_container'])
        next if @top_containers.include?(sub['top_container']['ref'])
        @top_containers << sub['top_container']['ref']
       
        # We get the Series ( the ancestor AO with the level == 'series' ) and
        # the name of the AO we're processing
        container_row = [@series, obj.display_string] 

        # Top Container time
        top = sub['top_container']['_resolved']

        # this will give us: 
        #  "#{name} [#{depth}d, #{height}h, #{width}w #{dimension_units}] extent measured by #{extent_dimension}"
        container_row << value_or_blank( top, %w( container_profile _resolved display_string ))

        container_row << "#{value_or_blank( top, %w( type ))}: #{value_or_blank( top, %w( indicator ))}"
       
        container_row << value_or_blank(top, %w( barcode ))

        # these get the grandchild SubContainers of the Top Container
        # e.g. Carton: 1 and Folder: 71
        container_row << [ value_or_blank( sub, %w( type_2 )), value_or_blank( sub, %w( indicator_2 ) ) ]
          .reject { |v| v.empty? }.join(":") 
        container_row << [ value_or_blank( sub, %w( type_3 )), value_or_blank( sub, %w( indicator_3 ) ) ]
          .reject { |v| v.empty? }.join(":") 

        
        current_location = top["container_locations"].find { |loc| loc["status"] === 'current'  } || {}
        container_row << value_or_blank( current_location, %w( _resolved title  ) ) 

        rows << container_row
      end
      rows.push(*generate_label_rows(obj.children))

    end
    
    rows
  end    
end
