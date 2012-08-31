def init
  super
  sections.last.place(:specs).before(:source)
end
