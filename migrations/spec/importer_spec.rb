require_relative "spec_helper"
require_relative "../lib/bootstrap"



describe "ASpaceImport::Importer" do

  before(:each) do
    @repo_id = create(:json_repo).id
    ASpaceImport::Importer.destroy_importers
  end


  it "should be able to create and register an importer sub-class" do
    ASpaceImport::Importer.importer :foo do
      def greet; "bar"; end
    end
    
    ASpaceImport::Importer.create_importer(:importer => :foo, :repo_id => @repo_id).greet.should eq("bar")
  end
  

  it "should not let two importers be registered  under the same key" do
    expect { ASpaceImport::Importer.importer :sgml do "Imports stuff" end }.to_not raise_error
    expect { ASpaceImport::Importer.importer :sgml do "Imports other stuff" end }.to raise_error
  end
end

