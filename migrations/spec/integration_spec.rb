require_relative "spec_helper.rb"


describe 'ASpaceImport' do
  
  
  before(:all) do
    
    start_backend
    @vocab_uri = make_test_vocab  
  end
  
  before(:each) do
    @repo = create(:json_repo)
    @repo_id = @repo.class.id_for(@repo.uri)
    
    @opts = {
      :repo_id => @repo_id,
      :vocab_uri => build(:json_vocab).class.uri_for(2)
    }
    
  end
  
  after(:each) do
    @opts = {}
  end
  
  after(:all) do
    stop_backend
  end

  # Turning off for now b/c of Derby length issues with this EAD.
  # it "can import the file at examples/ead/archon-tracer.xml" do
  # 
  #   @opts.merge!({
  #           :input_file => '../examples/ead/archon-tracer.xml', 
  #           :importer => 'ead',
  #           :quiet => true
  #           })
  # 
  #   @i = ASpaceImport::Importer.create_importer(@opts)
  #   
  #   @i.run
  #   result = @i.report.split(/\n/)
  #   result.shift.should match(/Aspace Import Report/)
  #   result.each do |r|
  #     r.should match(/^Saved: .*[0-9]$/)
  #   end
  #   
  # end
  
  it "can import the file at examples/ead/ferris.xml" do
  
    @opts.merge!({
            :input_file => '../examples/ead/ferris.xml', 
            :importer => 'ead',
            :quiet => true
            })

    @i = ASpaceImport::Importer.create_importer(@opts)
    
    @i.run
    result = @i.report.split(/\n/)
    result.shift.should match(/Aspace Import Report/)
    result.each do |r|
      r.should match(/^Saved: .*[0-9]$/)
    end
    
  end
  
  
  it "can import the file at examples/eac/feynman-richard-phillips-1918-1988-cr.xml" do
  
    @opts.merge!({
            :input_file => '../examples/eac/feynman-richard-phillips-1918-1988-cr.xml', 
            :importer => 'eac',
            :quiet => true
            })

    @i = ASpaceImport::Importer.create_importer(@opts)
    
    @i.run
    result = @i.report.split(/\n/)
    result.shift.should match(/Aspace Import Report/)
    result.each do |r|
      r.should match(/^Saved: .*[0-9]$/)
    end
    
  end
  
  
  it "can import the file at examples/marc/american-communist.xml" do
  
    @opts.merge!({
            :input_file => '../examples/marc/american-communist.xml', 
            :importer => 'marcxml',
            :quiet => true
            })

    @i = ASpaceImport::Importer.create_importer(@opts)
    
    @i.run
    result = @i.report.split(/\n/)
    result.shift.should match(/Aspace Import Report/)
    result.each do |r|
      r.should match(/^Saved: .*[0-9]$/)
    end
    result.count.should eq(10)
    
  end


end

