require "spec_helper"
require_relative "../app/lib/bulk_import/lang_handler"

describe "Language Handler" do
  before(:each) do
    @report = BulkImportReport.new
    @report.new_row(1)
    current_user = User.find(:username => "admin")
    @lh = LangHandler.new(current_user)
  end

  def current_row
    @report.instance_variable_get(:@current_row)
  end

  def hash_it(obj)
    ASUtils.jsonmodels_to_hashes(obj)
  end

  it "creates a language  (no script)" do
    lang = @lh.create_language("eng", nil, nil, true, @report)
    hsh = hash_it(lang)
    expect(hsh[0]["language_and_script"]["language"]).to eq("eng")
    expect(hsh[0]["notes"]).to eq([])
    expect(hsh[0]["language_and_script"]["script"]).to eq(nil)
  end

  it "fails to create a non-existent language (dothraki)" do
    lang = @lh.create_language("dth", nil, nil, true, @report)
    expect(lang).to eq([])
    expect(current_row.errors[0]).to start_with("Cannot validate language")
  end

  # note to self: there should be an error message in the report
  it "try to create a script with no language" do
    lang = @lh.create_language(nil, "latn", nil, true, @report)
    expect(lang).to eq([])
  end

  it "creates a language material note" do
    lang = @lh.create_language(nil, nil, "<p>This is a note!</p>", true, @report)
    hsh = hash_it(lang)
    note = hsh[0]["notes"][0]
    expect(note["content"][0]).to eq("<p>This is a note!</p>")
  end
  it "creates a non-publish language material note" do
    lang = @lh.create_language(nil, nil, "<p>This is an unpublished note!</p>", false, @report)
    hsh = hash_it(lang)
    note = hsh[0]["notes"][0]
    expect(note["content"][0]).to eq("<p>This is an unpublished note!</p>")
    expect(note["publish"]).to eq(false)
  end
  it "handles an ill-formed lang material note" do
    lang = @lh.create_language(nil, nil, "<p>This is a <strong>bad unpublished note!</p>", false, @report)
    expect(lang).to eq([])
    expect(current_row.errors[0]).to start_with("langmaterial note is not wellformed:")
  end

  it "creates a language and a lang material note" do
    lang = @lh.create_language("ara", nil, "<p>This is an Arabic note!</p>", false, @report)
    hsh = hash_it(lang)
    expect(hsh[0]["language_and_script"]["language"]).to eq("ara")
    expect(hsh[0]["language_and_script"]["script"]).to eq(nil)
    note = hsh[1]["notes"]
    expect(note[0]["publish"]).to eq(false)
    expect(note[0]["type"]).to eq("langmaterial")
    expect(note[0]["content"][0]).to eq("<p>This is an Arabic note!</p>")
  end

  it "creates a language, BAD script, and lang material note" do
    lang = @lh.create_language("ara", "arab", "<p>This is an Arabic note!</p>", false, @report)
    hsh = hash_it(lang)
    expect(hsh[0]["language_and_script"]["language"]).to eq("ara")
    expect(current_row["errors"][0]).to start_with("Cannot validate a language script")
    note = hsh[1]["notes"]
    expect(note[0]["publish"]).to eq(false)
    expect(note[0]["type"]).to eq("langmaterial")
    expect(note[0]["content"][0]).to eq("<p>This is an Arabic note!</p>")
  end
  it "creates a language, and lang material note" do
    lang = @lh.create_language("ara", "Arab", "<p>This is an Arabic note!</p>", false, @report)
    hsh = hash_it(lang)
    expect(hsh[0]["language_and_script"]["language"]).to eq("ara")
    expect(hsh[0]["language_and_script"]["script"]).to eq("Arab")
    note = hsh[1]["notes"]
    expect(note[0]["publish"]).to eq(false)
    expect(note[0]["type"]).to eq("langmaterial")
    expect(note[0]["content"][0]).to eq("<p>This is an Arabic note!</p>")
  end
end
