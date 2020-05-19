require "spec_helper"
require_relative "../app/lib/bulk_import/notes_handler"

describe "Notes Handler" do
  before(:each) do
    @nh = NotesHandler.new
  end

  def hash_it(obj)
    ASUtils.jsonmodels_to_hashes(obj)
  end

  it "creates a published singlepart ao note" do
    note = @nh.create_note("bibliography", "<p>John Q Public was born in Washington, DC in 1958</p>", true, false)
    hsh = hash_it(note)
    expect(hsh["jsonmodel_type"]).to eq("note_bibliography")
    expect(hsh["type"]).to eq("bibliography")
    expect(hsh["content"][0]).to eq("<p>John Q Public was born in Washington, DC in 1958</p>")
    expect(hsh["publish"]).to eq(true)
  end
  it "creates an upublished singlepart ao note" do
    note = @nh.create_note("bibliography", "<p>John Q Public was born in Washington, DC in 1958</p>", false, false)
    hsh = hash_it(note)
    expect(hsh["jsonmodel_type"]).to eq("note_bibliography")
    expect(hsh["type"]).to eq("bibliography")
    expect(hsh["content"][0]).to eq("<p>John Q Public was born in Washington, DC in 1958</p>")
    expect(hsh["publish"]).to eq(false)
  end

  it "creates a published multipart ao note" do
    note = @nh.create_note("prefercite", "US Government,<quot>John Q Public</quot>, <strong>Washington, DC</strong>: 1978", true, false)
    hsh = hash_it(note)
    expect(hsh["jsonmodel_type"]).to eq("note_multipart")
    expect(hsh["type"]).to eq("prefercite")
    expect(hsh["publish"]).to eq(true)
    subnote = hsh["subnotes"][0]
    expect(subnote["jsonmodel_type"]).to eq("note_text")
    expect(subnote["content"]).to eq("US Government,<quot>John Q Public</quot>, <strong>Washington, DC</strong>: 1978")
  end
  it "creates an unpublished multipart ao note" do
    note = @nh.create_note("prefercite", "US Government,<quot>John Q Public</quot>, <strong>Washington, DC</strong>: 1978", false, false)
    hsh = hash_it(note)
    expect(hsh["jsonmodel_type"]).to eq("note_multipart")
    expect(hsh["type"]).to eq("prefercite")
    expect(hsh["publish"]).to eq(false)
    subnote = hsh["subnotes"][0]
    expect(subnote["jsonmodel_type"]).to eq("note_text")
    expect(subnote["content"]).to eq("US Government,<quot>John Q Public</quot>, <strong>Washington, DC</strong>: 1978")
  end
  it "attempts to create a non-supported type for note " do
    expect {
      note = @nh.create_note("originalslochuh", "hi there!", false, false)
    }.to raise_error("Note type 'originalslochuh' is not supported")
  end
  it "attempts to create a digital_object type for ao note " do
    expect {
      note = @nh.create_note("digital_object", "hi there!", false, false)
    }.to raise_error("Note type 'digital_object' is not supported")
  end
  it "creates a do note " do
    note = @nh.create_note("altformavail", "Digital hi there!", false, true)
    hsh = hash_it(note)
    expect(hsh["jsonmodel_type"]).to eq("note_digital_object")
    expect(hsh["type"]).to eq("altformavail")
    expect(hsh["content"][0]).to eq("Digital hi there!")
    expect(hsh["publish"]).to eq(false)
  end
end
