require "spec_helper"
require_relative "../app/lib/bulk_import/cv_list"

describe "Controlled Value List" do
  it "should instantiate as a Control Value list" do
    current_user = User.find(:username => "admin")
    subject_sources = CvList.new("subject_source", current_user)
    expect(subject_sources.length).to be > 0
  end
  it "should return a value for a translation" do
    current_user = User.find(:username => "admin")
    subject_sources = CvList.new("subject_source", current_user)
    value = subject_sources.value("local")
    expect(value).to eq("local")
  end

  it "should return the same value for a value" do
    current_user = User.find(:username => "admin")
    subject_sources = CvList.new("subject_source", current_user)
    value = subject_sources.value("Local sources")
    expect(value).to eq("local")
  end

  it "should throw an exception for an invalid translation or value" do
    expect {
      current_user = User.find(:username => "admin")
      subject_sources = CvList.new("subject_source", current_user)
      value = subject_sources.value("Universal sources")
    }.to raise_error(Exception)
  end
end
