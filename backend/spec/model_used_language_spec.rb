require_relative 'spec_helper'

describe 'UsedLanguage model' do
  it "allows used_language records to be created" do
    ul = UsedLanguage.create_from_json(build(:json_used_language))
    expect(UsedLanguage[ul[:id]]).to_not eq(nil)
  end

  it "expects a used language to have either a language or a note" do
    expect {
      UsedLanguage.create_from_json(build(:json_used_language, :language => nil,
                                                          :notes => []))
    }.to raise_error(JSONModel::ValidationException)

    expect {
      UsedLanguage.create_from_json(build(:json_used_language, :language => nil))
    }.to_not raise_error(JSONModel::ValidationException)

    expect {
      UsedLanguage.create_from_json(build(:json_used_language, :notes => []))
    }.to_not raise_error(JSONModel::ValidationException)
  end
end
