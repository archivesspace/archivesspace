require "../lib/bootstrap.rb"

# TODO - Consider writing tests for import method

describe ASpaceImporter do
  it "should initially have 0 registered importer subclasses" do
    ASpaceImporter.importer_count.should == 0
  end
  it "should be able to create and register an importer sub-class" do
    ASpaceImporter.importer :yo do
      def greet; puts "hi"; end
    end
  end
  # Note: perhaps this state is unreliable if tests are concatenated?
  it "should have 1 registered importer at this point in the present test" do
    ASpaceImporter.importer_count.should == 1
  end
  it "should not let two importers be registered  under the same key" do
    expect { ASpaceImporter.importer :tschusie do "Hallo" end }.to_not raise_error
    expect { ASpaceImporter.importer :tschusie do "HiHi" end }.to raise_error
  end
  it "should not be able to instantiate an importer class that is clearly unusable" do
    expect { ASpaceImporter.create_importer( {:importer => :yo} ) }.to raise_error
  end
  it "should be able to instantiate an importer class that appears to be usable" do
    ASpaceImporter.importer :hey do 
      def self.profile; "blah"; end
      def run; "blech"; end
    end
    expect { ASpaceImporter.create_importer( {:importer => :hey} ) }.to_not raise_error
  end
end

