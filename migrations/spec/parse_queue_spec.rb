require_relative "spec_helper"

describe "ASpaceImport::RecordBatch" do

  before(:all) do

  end


  before(:each) do
    JSONModel::set_repository(2)
    @batch = ASpaceImport::RecordBatch.new(:log => Logger.new(STDOUT), :dry => true)
  end


  it "has an in-memory working area for objects pushed into it" do

    5.times do
      @batch << build(:json_archival_object)
    end

    @batch.working_area.length.should eq(5)
  end


  it "stores records in a file when the working area is flushed" do

    2.times do
      @batch << build(:json_archival_object)
    end

    @batch.working_area.length.should eq(2)

    @batch.flush

    @batch.working_area.length.should eq(0)

    wf = @batch.instance_variable_get(:@working_file)

    wf.close
    str = "["
    File.open(wf.path).each do |line|
      puts "Reading line #{line}"
      str << "#{line.gsub(/\n/,'')},"
    end
    str << "]"
    str.sub!(/,\]\Z/, "]")


    ASUtils.json_parse(str).length.should eq(2)
  end


  it "saves all cached objects and sends the response to a block" do

    2.times do
      @batch << build(:json_archival_object)
    end

    results = ""

    @batch.save! do |response|
      response.read_body do |chunk|
        results << chunk
      end
    end

    ASUtils.json_parse(results).last['saved'].length.should eq(2)
  end
end
