require 'spec_helper'

describe 'Language and script model' do


  it "Allows a language and script subrecord to be created" do

    language_and_script = LanguageAndScript.create_from_json(JSONModel(:language_and_script).
                                 from_hash({
                                             "language" => "eng",
                                             "script" => "Latn"
                                           }))

    expect(LanguageAndScript[language_and_script[:id]].language).to eq("eng")
    expect(LanguageAndScript[language_and_script[:id]].script).to eq("Latn")
  end


end
