module ImportSpecHelpers

  def load_repo
    @repo = create(:json_repo)
    @repo_id = @repo.class.id_for(@repo.uri)
  end


  def run_import_and_load_records
    raise "No @test_path instance variable. Can't locate a text import file." unless @test_path

    opts = {
     :repo_id => @repo_id,
     :vocab_uri => build(:json_vocab).class.uri_for(2),
     :input_file => @test_path,
     :importer => 'ead',
     :quiet => true
    }

    @i = ASpaceImport::Importer.create_importer(opts)

    @count = 0
    @saved = {}

    @i.run_safe do |msg|
     if msg['saved']
       @count = msg['saved'].count
       @saved = msg['saved']
     end
    end

    @corps = []
    @saved.keys.select {|k| k =~ /\/corporate_entities\//}.each do |k|
     @corps << JSONModel::HTTP.get_json(@saved[k][0])
    end

    @families = []
    @saved.keys.select {|k| k =~ /\/families\//}.each do |k|
     @families << JSONModel::HTTP.get_json(@saved[k][0])
    end

    @people = []
    @saved.keys.select {|k| k =~ /\/people\//}.each do |k|
     @people << JSONModel::HTTP.get_json(@saved[k][0])
    end

    @subjects = []
    @saved.keys.select {|k| k =~ /\/subjects\//}.each do |k|
     @subjects << JSONModel::HTTP.get_json(@saved[k][0])
    end

    @digital_objects = []
    @saved.keys.select {|k| k =~ /\/digital_objects\//}.each do |k|
     @digital_objects << JSONModel::HTTP.get_json(@saved[k][0])
    end

    @archival_objects = {}
    @saved.keys.select {|k| k =~ /\/archival_objects\//}.each do |k|
     a = JSONModel::HTTP.get_json(@saved[k][0])
     a['title'].match(/C([0-9]{2})/) do |m|
       @archival_objects[m[1]] = a
     end
    end

    @resource = JSONModel::HTTP.get_json(@saved.values.last[0])
  end
end