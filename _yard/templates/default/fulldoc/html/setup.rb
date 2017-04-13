def init

  super

  schemata = Registry.all(:schema)
  
  schemata.each do |object|
    begin
      serialize(object)
    rescue => e
      path = options.serializer.serialized_path(object)
      log.error "Exception occurred while generating '#{path}'"
      log.backtrace(e)
    end
  end
end    


# Generate a searchable schema list in the output
def generate_schema_list
  puts "GENERATE SCHEMA LIST"
   # load all the features from the Registry
   @items = Registry.all(:schema).sort { |a,b| a.name.downcase <=> b.name.downcase }

   @list_title = "Schema List"
   @list_type = "schema"

   # optional: the specified stylesheet class
   # when not specified it will default to the value of @list_type
   @list_class = "schema"

   # Generate the full list html file with named feature_list.html
   # @note this file must be match the name of the type
   asset('schema_list.html', erb(:full_list))
end


def link_schema(item)
  "<div class='item'><span class='object_link'><a href='#{item}.html' title='#{item}' >#{item.to_s.sub(/_schema/,'')}</a></span></div>"
 # linkify(item)
end
  



