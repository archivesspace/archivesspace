require 'spec_helper'

describe 'External ID model' do

  it "stores external IDs and gives them back" do
    obj = build(:json_accession, {
                                  'external_ids' => [{
                                                      'source' => 'MyILMS',
                                                      'external_id' => '40440444'
                                                     }]
                                 })

    record = Accession.create_from_json(obj)

    Accession.to_jsonmodel(record).external_ids.first['external_id'].should eq('40440444')
  end


  it "deletes external IDs when the referenced object is deleted" do
    obj = build(:json_accession, {
                                  'external_ids' => [{
                                                       'source' => 'MyILMS',
                                                       'external_id' => '40440444'
                                                     }]
                                 })

    record = Accession.create_from_json(obj)

    record.external_id.count.should eq(1)
    external_id = record.external_id.first

    record.delete

    # Gone now, so raises an error on reload.
    expect { external_id.reload }.to raise_error(Sequel::Error)

  end
end
