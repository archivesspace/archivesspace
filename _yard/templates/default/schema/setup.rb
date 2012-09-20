include T('default/module')

def init
  sections :schema
end

def schema

  @schema = object

  # Nest the item type inside the "array" string if the 
  # property takes an array, e.g., (array (JSONModel(:subject)))
  @schema[:properties].each do |p, defn|    

    next unless defn["type"]
    if defn["type"] == 'array' and defn["items"]["type"]
      defn["type"] += " (#{defn["items"]["type"]})"
    end
  end
  
  erb(:schema)
end