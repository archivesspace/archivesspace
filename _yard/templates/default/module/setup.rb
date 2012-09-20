def init
  super
  sections.place(:specs).before(:method_summary)
  # sections.place(:schemata).before(:method_summary)
end

def specs
  erb(:specs)  
end

def schemata
  object.children.each do |child|
    if child.type == :schema
      @schemata ||= []
      @schemata.push(child)
    end
  end
  return unless @schemata
  erb(:schemata)
end


def children
  @inner = [[:modules, []], [:classes, []], [:schemata, []]]
  object.children.each do |child|
    @inner[0][1] << child if child.type == :module
    @inner[1][1] << child if child.type == :class
    @inner[2][1] << child if child.type == :schema
  end
  @inner.map! {|v| [v[0], run_verifier(v[1].sort_by {|o| o.name.to_s })] }
  return if (@inner[0][1].size + @inner[1][1].size) == 0
  erb(:children)
end