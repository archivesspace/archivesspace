require 'spec_helper'

describe 'LanguageAndScriptOfDescription model' do
  it "defaults is_primary to false" do
    record = LanguageAndScriptOfDescription.create_from_json(
      JSONModel(:language_and_script_of_description).from_hash(
        "language" => "fra",
        "script"   => "Latn"
      )
    )

    expect(LanguageAndScriptOfDescription[record.id].is_primary).to eq(0)
  end

  it "requires language to be present" do
    expect {
      LanguageAndScriptOfDescription.create_from_json(
        JSONModel(:language_and_script_of_description).from_hash(
          "script" => "Latn"
        )
      )
    }.to raise_error(JSONModel::ValidationException)
  end

  it "requires script to be present" do
    expect {
      LanguageAndScriptOfDescription.create_from_json(
        JSONModel(:language_and_script_of_description).from_hash(
          "language" => "eng"
        )
      )
    }.to raise_error(JSONModel::ValidationException)
  end
end
