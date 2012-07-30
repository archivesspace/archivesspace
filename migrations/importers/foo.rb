
ASpaceImporter.importer :foo do
  def display
    puts "Here is Foo: a simple importer"
  end
  def run
    test_accession = {  
                      "title" => "Foo Accession", 
                      "accession_id_0" => "abc123",
                      "content_description" => "foooo",
                      "condition_description" => "terrible",
                      "accession_date" => "2012-01-01",
                      "fake_field" => "A field the schema should filter out"
                      }  
    #Good import:
    import :accession, test_accession

    #Bad Import - Good type, bad hash
    import :accession, "flub"
    
    #Bad Import - Bad type, good hash
    import :dfsdfsdfs, test_accession
    
    
  end  
end





#class FooImporter < ASpaceImporter
#  register_import_key :foo
#  def display 
#    puts "Here I am, Foo"
#  end
#end

