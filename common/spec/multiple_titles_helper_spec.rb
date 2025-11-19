require 'multiple_titles_helper'

describe MultipleTitlesHelper do
  describe "determine_primary_title" do
    it "returns the primary title based on the provided locale" do
      titles = [
        {"title" => "English Title", "language" => "eng"},
        {"title" => "日本語のタイトル", "language" => "jpn"}
      ]
      expect(MultipleTitlesHelper.determine_primary_title(titles, :en)).to eq("English Title")
      expect(MultipleTitlesHelper.determine_primary_title(titles, :ja)).to eq("日本語のタイトル")
    end

    xit "returns a formal title if it exists regardless of locale" do
      # TODO: delete this test if decision to remove this rule sticks
      titles = [
        {"title" => "English Title", "language" => "eng", "type" => "formal"},
        {"title" => "日本語のタイトル", "language" => "jpn"},
      ]
      expect(MultipleTitlesHelper.determine_primary_title(titles, :ja)).to eq("English Title")
    end

    it "falls back to the default language if no formal or preferred-language title exists" do
      titles = [
        {"title" => "English Title", "language" => "eng"},
        {"title" => "日本語のタイトル", "language" => "jpn"}
      ]
      # The default default language is English
      expect(MultipleTitlesHelper.determine_primary_title(titles, :fr)).to eq("English Title")
      expect(MultipleTitlesHelper.determine_primary_title(titles, :fr, "jpn")).to eq("日本語のタイトル")
    end

    it "returns the first title if no preferred title can be determined" do
      titles = [
        {"title" => "Titre Français", "language" => "fra"},
        {"title" => "English Title", "language" => "eng"},
        {"title" => "日本語のタイトル", "language" => "jpn"}
      ]
      expect(MultipleTitlesHelper.determine_primary_title(titles, :de, "spa")).to eq("Titre Français")
    end
  end
end
