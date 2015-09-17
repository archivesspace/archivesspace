class LabelModel < ASpaceExport::ExportModel
  model_for :labels

  include JSONModel
  include ASpaceExport::LazyChildEnumerations

  @ao = Class.new do
    include ASpaceExport::LazyChildEnumerations

    def initialize(tree, repo_id)
      @repo_id = repo_id
      @children = tree ? tree['children'] : []
      @child_class = self.class
      @json = nil
      RequestContext.open(:repo_id => repo_id) do
        rec = URIResolver.resolve_references(ArchivalObject.to_jsonmodel(tree['id']), ['subjects', 'linked_agents', 'digital_object', 'parent'], {'ASPACE_REENTRANT' => false})
        @json = JSONModel::JSONModel(:archival_object).new(rec)
      end
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
    @children = @json.tree['_resolved']['children']
    @child_class = self.class.instance_variable_get(:@ao)
  end

  def stream_rows(y)
    each_row(self, y)
  end


  def each_row(obj, y)
    obj.children_indexes.each do |i|
      child = obj.get_child(i)

      generate_label_rows(child).each do |row|
        fullrow = self
        y << fullrow.join("\t") + "\r"
        end

      each_row(child, y)

    end

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
      rows

    end

    rows
  end
end
