def init
  super
  sections.place(:specs).before(:children)
  sections.place(:endpoints).after(:children)
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
