def init
  
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


def serialize(object)
  
  options.object = object
  options.basepath = "./docs/doc"
  
  options.serializer = YARD::Serializers::FileSystemSerializer.new(:basepath => options.basepath, :extension => 'txt')
  
  Templates::Engine.with_serializer(object, options.serializer) do
    T('schema').run(options)
  end
end




