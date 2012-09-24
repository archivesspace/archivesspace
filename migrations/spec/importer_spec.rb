require_relative "spec_helper"
require_relative "../lib/bootstrap"



describe "ASpaceImport::Importer" do

  before(:each) do
    ASpaceImport::Importer.destroy_importers
  end

  it "should initially have 0 registered importer subclasses" do
    ASpaceImport::Importer.importer_count.should == 0
  end


  it "should be able to create and register an importer sub-class" do
    ASpaceImport::Importer.importer :foo do
      def greet; puts "bar"; end
    end
  end


  it "should have two registered importers after registering two" do
    ASpaceImport::Importer.importer :abc do "Imports stuff" end
    ASpaceImport::Importer.importer :def do "Imports stuff" end
    ASpaceImport::Importer.importer_count.should == 2
  end
  

  it "should not let two importers be registered  under the same key" do
    expect { ASpaceImport::Importer.importer :sgml do "Imports stuff" end }.to_not raise_error
    expect { ASpaceImport::Importer.importer :sgml do "Imports other stuff" end }.to raise_error
  end
  
  
  it "should be able to instantiate an importer class that appears to be usable" do
    ASpaceImport::Importer.importer :hey do
      def self.profile; "blah"; end
      def run; "blech"; end
    end
    expect { ASpaceImport::Importer.create_importer({:importer => :hey, :repo_id => '1'}) }.to_not raise_error
  end
end

