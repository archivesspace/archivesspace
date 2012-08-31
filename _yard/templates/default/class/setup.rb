def init
  super
  puts "INIT #{:namespace}"
  sections.place(:specs).before(:children)
  sections.place(:endpoints).before(:children)
end


def endpoints
  object.children.each do |child|
    if child.type == :endpoint
      @endpoints ||= []
      @endpoints.push(child)
    end
  end
  return unless @endpoints
  erb(:endpoints)
end
