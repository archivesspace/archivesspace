require 'spec_helper'

describe 'LanguageAndScriptOfDescription model' do
  it 'requires language to be present' do
    expect {
      LanguageAndScriptOfDescription.create_from_json(
        JSONModel(:language_and_script_of_description).from_hash(
          "script" => "Latn"
        )
      )
    }.to raise_error(JSONModel::ValidationException)
  end

  it 'requires script to be present' do
    expect {
      LanguageAndScriptOfDescription.create_from_json(
        JSONModel(:language_and_script_of_description).from_hash(
          "language" => "eng"
        )
      )
    }.to raise_error(JSONModel::ValidationException)
  end
end
