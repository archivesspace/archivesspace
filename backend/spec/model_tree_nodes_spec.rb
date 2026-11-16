require 'spec_helper'

describe 'TreeNodes' do
  let(:resource) { create(:json_resource) }

  def archival_object
    ArchivalObject[create(:json_archival_object, :resource => {'ref' => resource.uri}).id]
  end

  describe 'retry_db_update' do
    it 'retries a position clash, rolling back what the failed attempt wrote' do
      first = archival_object
      second = archival_object
      attempts = 0

      ArchivalObject.retry_db_update do
        attempts += 1
        if attempts == 1
          ArchivalObject.filter(:id => first.id).update(:title => 'Written by the failed attempt')
          ArchivalObject.filter(:id => second.id).update(:position => first.position)
        end
      end

      expect(attempts).to eq(2)
      expect(ArchivalObject[first.id].title).to eq(first.title)
      expect(ArchivalObject[second.id].position).to eq(second.position)
    end

    it 'raises a failed validation without retrying' do
      attempts = 0

      expect {
        ArchivalObject.retry_db_update do
          attempts += 1
          raise Sequel::ValidationFailed.new('invalid')
        end
      }.to raise_error(Sequel::ValidationFailed)

      expect(attempts).to eq(1)
    end
  end

  it 'leaves no record behind when a nested record rejects the create' do
    instances = 2.times.map {
      build(:json_instance_digital, :is_representative => true, :digital_object => {'ref' => create(:json_digital_object).uri})
    }
    json = build(:json_archival_object, :resource => {'ref' => resource.uri}, :instances => instances)

    expect {
      expect {
        ArchivalObject.create_from_json(json)
      }.to raise_error(Sequel::ValidationFailed) { |e| expect(e.errors.keys).to eq(['instances/1/is_representative']) }
    }.not_to change { ArchivalObject.any_repo.count }
  end
end
