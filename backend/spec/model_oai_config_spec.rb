require 'spec_helper'

describe 'OAIConfig model' do

  def update_oai_config(properties)
    oai_config = JSONModel(:oai_config).all.first
    properties.each do |property, value|
      oai_config[property.to_s] = value
    end
    oai_config.save

    JSONModel(:oai_config).all.first
  end

  def repository_set(properties = {})
    {
      'set_name' => 'a_repository_set',
      'set_description' => 'Some repositories',
      'repo_codes' => ['oai_test']
    }.merge(properties)
  end

  def sponsor_set(properties = {})
    {
      'set_name' => 'a_sponsor_set',
      'set_description' => 'Some sponsors',
      'sponsor_names' => ['A sponsor']
    }.merge(properties)
  end

  it "does not create an additional row in the OAIConfig table" do
    expect {OAIConfig.create(:oai_admin_email => "a@b.com",
                            :oai_repository_name => "foo",
                            :oai_record_prefix => "bar")}.to raise_error(Sequel::ValidationFailed)
  end

  it "requires oai_repository_name to be set" do
    oc = OAIConfig.first

    expect { oc.update(:oai_repository_name => nil,
                       :oai_admin_email => "c@d",
                       :oai_record_prefix => "sadf") }.to raise_error(Sequel::ValidationFailed)
  end

  it "requires oai_admin_email to be set" do
    oc = OAIConfig.first

    expect { oc.update(:oai_repository_name => "foo",
                       :oai_admin_email => nil,
                       :oai_record_prefix => "sadf") }.to raise_error(Sequel::ValidationFailed)
  end

  it "requires oai_record_prefix to be set" do
    oc = OAIConfig.first

    expect { oc.update(:oai_repository_name => "foo",
                       :oai_admin_email => "a@b.com",
                       :oai_record_prefix => nil) }.to raise_error(Sequel::ValidationFailed)
  end

  it "requires oai_admin_email to be an email address" do
    oc = OAIConfig.first

    expect { oc.update(:oai_repository_name => "foo",
                       :oai_admin_email => "bargmail.com",
                       :oai_record_prefix => "bim") }.to raise_error(Sequel::ValidationFailed)
  end

  # ANW-2707
  describe "repository sets and sponsor sets" do

    it "stores any number of repository sets and sponsor sets" do
      updated = update_oai_config('oai_repository_sets' => [repository_set('set_name' => 'repos_1'),
                                                            repository_set('set_name' => 'repos_2',
                                                                           'repo_codes' => ['a', 'b'])],
                                  'oai_sponsor_sets' => [sponsor_set('set_name' => 'sponsors_1'),
                                                         sponsor_set('set_name' => 'sponsors_2',
                                                                     'sponsor_names' => ['x', 'y'])])

      expect(updated['oai_repository_sets'].map {|s| s['set_name']}).to eq(['repos_1', 'repos_2'])
      expect(updated['oai_repository_sets'][1]['repo_codes']).to eq(['a', 'b'])

      expect(updated['oai_sponsor_sets'].map {|s| s['set_name']}).to eq(['sponsors_1', 'sponsors_2'])
      expect(updated['oai_sponsor_sets'][1]['sponsor_names']).to eq(['x', 'y'])
    end

    it "removes sets that are no longer in the record" do
      update_oai_config('oai_repository_sets' => [repository_set('set_name' => 'repos_1'),
                                                  repository_set('set_name' => 'repos_2')])

      updated = update_oai_config('oai_repository_sets' => [repository_set('set_name' => 'repos_2')])

      expect(updated['oai_repository_sets'].map {|s| s['set_name']}).to eq(['repos_2'])
      expect(OAIRepositorySet.all.count).to eq(1)
    end

    it "requires a name, a description and at least one value" do
      ['set_name', 'set_description', 'repo_codes'].each do |property|
        expect {
          update_oai_config('oai_repository_sets' => [repository_set.reject {|k, _| k == property}])
        }.to raise_error(JSONModel::ValidationException)
      end

      ['set_name', 'set_description', 'sponsor_names'].each do |property|
        expect {
          update_oai_config('oai_sponsor_sets' => [sponsor_set.reject {|k, _| k == property}])
        }.to raise_error(JSONModel::ValidationException)
      end
    end

    it "rejects two sets sharing a name" do
      expect {
        update_oai_config('oai_repository_sets' => [repository_set('set_name' => 'same'),
                                                    repository_set('set_name' => 'same')])
      }.to raise_error(JSONModel::ValidationException)

      expect {
        update_oai_config('oai_repository_sets' => [repository_set('set_name' => 'same')],
                          'oai_sponsor_sets' => [sponsor_set('set_name' => 'same')])
      }.to raise_error(JSONModel::ValidationException)
    end

    it "rejects a set named after a level of description" do
      level = BackendEnumSource.values_for("archival_record_level").first

      expect {
        update_oai_config('oai_repository_sets' => [repository_set('set_name' => level)])
      }.to raise_error(JSONModel::ValidationException)
    end
  end
end
