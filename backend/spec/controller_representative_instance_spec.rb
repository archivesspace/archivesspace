require 'spec_helper'

describe 'Representative instance through the API' do
  def digital_instance(is_representative)
    build(:json_instance_digital, :is_representative => is_representative, :digital_object => {'ref' => create(:json_digital_object).uri})
  end

  def representative_flags(record)
    record.class.find(record.id).instances.map { |instance| instance['is_representative'] }
  end

  def rejected_as_second_representative
    raise_error(JSONModel::ValidationException) { |e| expect(e.errors.keys).to eq(['instances/1/is_representative']) }
  end

  shared_examples 'a record with at most one representative instance' do |factory|
    it 'accepts one representative instance' do
      record = create(factory, :instances => [digital_instance(false), digital_instance(true)])

      expect(representative_flags(record)).to eq([false, true])
    end

    it 'rejects creating it with two representative instances' do
      expect {
        create(factory, :instances => [digital_instance(true), digital_instance(true)])
      }.to rejected_as_second_representative
    end

    it 'rejects updating it to two representative instances' do
      record = create(factory, :instances => [digital_instance(true), digital_instance(false)])
      json = record.class.find(record.id)
      json.instances[1]['is_representative'] = true

      expect { json.save }.to rejected_as_second_representative
    end
  end

  describe 'accession' do
    it_behaves_like 'a record with at most one representative instance', :json_accession
  end

  describe 'resource' do
    it_behaves_like 'a record with at most one representative instance', :json_resource
  end

  describe 'archival object' do
    it_behaves_like 'a record with at most one representative instance', :json_archival_object
  end
end
