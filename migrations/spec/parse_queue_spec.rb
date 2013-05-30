require_relative "spec_helper"

describe "ASpaceImport::ImportCache" do

  before(:all) do

    ASpaceImport::Batch.class_eval do
      def inspect
        @working_file.close
        str = "["
        File.open(@working_file.path).each do |line|
          puts "Reading line #{line}"
          str << "#{line.gsub(/\n/,'')},"
        end
        str << "]"
        str.sub!(/,\]\Z/, "]")

        @working_file.open

        arr = ASUtils.json_parse(str)
        arr.inspect
      end
    end
  end


  before(:each) do
    JSONModel::set_repository(2)
    @cache = ASpaceImport::ImportCache.new(:log => Logger.new(STDOUT), :dry => true)
  end


  it "works like an Array to push objects into a cache" do

    5.times do
      @cache << build(:json_archival_object)
    end

    @cache.length.should eq(5)
  end


  it "sends a popped member to the file-based cache, provided it has a uri" do

    batch = @cache.instance_variable_get(:@batch)

    2.times do
      @cache << build(:json_archival_object)
    end

    @cache.last.uri = nil
    @cache.pop

    @cache.length.should eq(1)
    eval(batch.inspect).length.should eq(0)


    @cache.pop

    @cache.length.should eq(0)
    eval(batch.inspect).length.should eq(1)
  end


  it "saves all cached objects and sends the response to a block" do

    2.times do
      @cache << build(:json_archival_object)
    end

    @cache.pop

    results = ""

    @cache.save! do |response|
      response.read_body do |chunk|
        results << chunk
      end
    end

    ASUtils.json_parse(results).last['saved'].length.should eq(2)

  end

end