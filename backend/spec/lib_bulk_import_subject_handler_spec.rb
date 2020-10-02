require "spec_helper"
require_relative "../app/lib/bulk_import/subject_handler"

describe "Subject Handler" do
  before(:each) do
    current_user = User.find(:username => "admin")
    @sh = SubjectHandler.new(current_user)
    @shv = SubjectHandler.new(current_user, true)
    @report = BulkImportReport.new
    @report.new_row(1)
    @id = nil
  end

  def build_return_key(id, term, type, source)
    errs = []
    subject = @sh.validate_subject(id, term, type, source, errs)
    key = @sh.key_for(subject)
    key
  end

  it "should validate and find errors in a subject" do
    errs = []
    subj = @shv.validate_subject(nil, "My Subject", "topical", "ingested", errs)
    expect(errs[0]).to start_with("NOT FOUND: 'ingested' not found ")
  end

  it "should build an entry in the subjects list with nil type and return a key" do
    key = build_return_key(nil, "My Subject", nil, "local")
    expect(key).to eq("My Subject local: topical")
  end

  it "should reject an entry with an invalid source (ingested)" do
    errs = []
    subject = @sh.validate_subject(nil, "My Subject", "topical", "ingested", errs)
    expect(errs[0]).to start_with("NOT FOUND: 'ingested' not found ")
  end

=begin
  it "should retrieve a subject entry by a key" do
    build_return_key(nil, "nicely done", nil, "local")
    subject = @sh.stored(@sh.instance_variable_get(:subjects), nil, "nicely done local: topical")
    expect(subject.term).to eq("nicely done")
  end
=end

  it "should create a subject" do
    errs = []
    subject = @sh.validate_subject(nil, "New School", "topical", "local", errs)
    subj = @sh.create_subj(subject)
    expect(subj[:id]).to_not be_nil
    expect(errs.empty?).to be(true)
    id = subj[:id]
    s = nil
    expect {
      s = Subject.get_or_die(id)
    }.not_to raise_error
    expect(s[:title]).to eq("New School")
    subj.delete
  end
  it "should create a subject with the default values" do
    errs = []
    subject = @sh.validate_subject(nil, "New School ingested", nil, nil, errs)
    expect(errs.empty?).to be(true)
    subj = @sh.create_subj(subject)
    expect(subj[:id].nil?).to be(false)
    id = subj[:id]
    s = nil
    expect {
      s = Subject.get_or_die(id)
    }.not_to raise_error
    expect(s[:title]).to eq("New School ingested")
    subj.delete
  end

  it "should find a subject from its ID" do
    errs = []
    subject = @sh.validate_subject(nil, "New School", "topical", "local", errs)
    expect(errs.empty?).to be(true)
    subj = @sh.create_subj(subject)
    id = subj[:id]
    subject = @sh.get_or_create(id, nil, nil, nil, $repo_id, @report)
    expect(subject[:id]).to eq(subj[:id])
  end

=begin

  it "should find a subject in the db by term with and without the source" do
    subj = @sh.get_or_create(nil, "New School", nil, "local", $repo_id, @report)
    subject = @sh.build(nil, "New School", "topical", "local")
    s = @sh.get_db_subj(subject, true, @report)
    expect(s[:id]).to eq(subj[:id])
    s = @sh.get_db_subj(subject, true, @report)
    expect(s[:id]).to eq(subject[:id])
  end
=end
end
