require 'spec_helper'

describe 'Language model' do


  it "Allows a language subrecord to be created" do

    language = Language.create_from_json(JSONModel(:language).
                                 from_hash({
                                             "language" => "eng",
                                             "script" => "Latn",
                                             "note" => "a language note",
                                           }))

    expect(Language[language[:id]].language).to eq("eng")
    expect(Language[language[:id]].script).to eq("Latn")
    expect(Language[language[:id]].note).to eq("a language note")
  end


end
