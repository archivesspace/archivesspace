include T('default/module')

def init
  sections :schema
end

def schema
  @schema = object
  erb(:schema)
end