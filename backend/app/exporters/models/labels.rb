class LabelModel < ASpaceExport::ExportModel
  model_for :labels
  
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
    @seen_top_containers = []
    
    @rows = generate_label_rows(self.children) 
  end
  
  
  def headers
    %w(Repository\ Name Resource\ Title  Resource\ Identifier Container Label)
  end
  
  
  def rows
    @rows.map {|r| [self.repo_name, self.title, self.identifier] + r }
  end
  

  def self.from_aspace_object(obj)
    labler = self.new(obj)
    
    labler
  end
    
  
  def self.from_resource(obj)
    labler = self.from_aspace_object(obj)
    
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
    return nil unless @json.tree.has_key?('_resolved') && @json.tree['_resolved']['children']
    
    ao_class = self.class.instance_variable_get(:@ao)
    
    children = @json.tree['_resolved']['children'].map { |subtree| ao_class.new(subtree) }
    
    children
  end
  
  
  def generate_label_rows(objects)

    rows = []
    
    objects.each do |obj|

      instances = obj.instances
      instances.each do |i|
        if i['sub_container']
          next if @seen_top_containers.include?(i['sub_container']['top_container']['ref'])
          @seen_top_containers << i['sub_container']['top_container']['ref']
        end

        c = i['container']
        next unless c
        crow = [] 
        if c['type_1'] && c['indicator_1'] 
          crow << "#{c['type_1']} #{c['indicator_1']}"
        end
        if c['barcode_1']
          crow << c['barcode_1']
        end
        rows << crow
      end
      rows.push(*generate_label_rows(obj.children))

    end
    
    rows
  end    
end
