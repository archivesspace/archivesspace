# class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
#   handles method_call(:describe)
#   
#   def process
#     objname = statement.parameters.first.jump(:string_content).source
#     if statement.parameters[1]
#       src = statement.parameters[1].jump(:string_content).source
#       objname += (src[0] == "#" ? "" : "::") + src
#     end
#     obj = {:spec => owner ? (owner[:spec] || "") : ""}
#     obj[:spec] += objname
#     parse_block(statement.last.last, owner: obj)
#   rescue YARD::Handlers::NamespaceMissingError
#   end
# end
# 
# class RSpecItHandler < YARD::Handlers::Ruby::Base
#   handles method_call(:it)
#   
#   def process
#     return if owner.nil?
#     obj = P(owner[:spec])
#     return if obj.is_a?(Proxy)
#     
#     (obj[:specifications] ||= []) << {
#       name: statement.parameters.first.jump(:string_content).source,
#       file: statement.file,
#       line: statement.line,
#       source: statement.last.last.source.chomp
#     }
#   end
# end

class SchemaHandler < YARD::Handlers::Ruby::Legacy::Base
  handles(/.*/)
  
  in_file(/schemas\/.*\.rb/)
  
  def process
    name = parser.file.sub(/\.rb/, '').sub(/.*\//, '') + "_schema"
    schema_object = register YARD::CodeObjects::SchemaObject.new(:root, name)
    
    schema_object[:schema] = schema_object[:source] = statement.to_s

    accession_browse_column_enum, resource_browse_column_enum, digital_object_browse_column_enum = nil
    
    s = eval("#{schema_object[:source]}")
    return "" unless s.is_a?(Hash) 
    
    schema_object[:uri] = s[:schema]["uri"]
    schema_object[:properties] = s[:schema]["properties"]


  end
end

# Requires Ripper (not currently available in JRuby)

# class SchemaHandler < YARD::Handlers::Ruby::Base
#   handles(/.*/)
#   
#   in_file(/schemas\/.*\.rb/)
#   
#   def process
#     puts "Schema Handler Process"
#     name = statement.file.sub(/\.rb/, '').sub(/.*\//, '') + "_schema"
#     schema_object = register YARD::CodeObjects::SchemaObject.new(:root, name)
#     schema_object[:schema] = schema_object[:source] = statement[0].source
# 
#     s = eval("{ #{schema_object[:source]} }")
#     schema_object[:uri] = s[:schema]["uri"]
#     schema_object[:properties] = s[:schema]["properties"]
# 
#   end
# end

# class EndpointHandler < YARD::Handlers::Ruby::Base
#   handles(/^Endpoint\.post/)
# 
#   def process
#     name = statement.jump(:tstring_content).source
#     
#     endpoint_object = register YARD::CodeObjects::EndpointObject.new(namespace, name)
#     
#     endpoint_object.source = statement.source
#     endpoint_object.describe
# 
#   end
# end


  
  
  



