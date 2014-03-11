require_relative "spec_helper"
require_relative '../app/converters/lib/parse_queue'
require_relative '../app/converters/lib/jsonmodel_wrap'

describe 'ParseQueue' do

  let (:test_record) {
    ASpaceImport::JSONModel(:archival_object).from_hash(build(:json_archival_object).to_hash)
  }

  let (:batch) {
    batch = ASpaceImport::RecordBatch.new
  }

  it "has an in-memory working area for objects pushed into it" do

    5.times do
      batch << test_record
    end

    batch.working_area.length.should eq(5)
  end


  it "stores records in a file when the working area is flushed" do
    file = double
    file.should_receive(:write).exactly(4).times

    batch = ASpaceImport::RecordBatch.new(:working_file => file)

    2.times do |i|
      batch << test_record
    end

    batch.working_area.length.should eq(2)
    batch.flush
    batch.working_area.length.should eq(0)
  end


  describe "deduping incoming records" do

    let (:test_record) {
      date_template = build(:json_date, :label => 'creation')
      date1 = JSONModel(:date).from_hash(date_template.to_hash)
      date2 = JSONModel(:date).from_hash(date_template.to_hash)

      resource = build(:json_resource,
                       :dates => [date1, date2])

      ASpaceImport::JSONModel(:resource).from_hash(resource.to_hash)
    }

    it "won't let two identical date subrecords go through" do
      batch << test_record

      batch.working_area.last.dates.length.should eq(1)
    end

  end
end
