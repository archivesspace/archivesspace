require "spec_helper"
require_relative "../app/controllers/lib/bulk_import/cv_list"

describe "Controlled Value List" do
  it "should instantiate as a Control Value list" do
      current_user = User.find(:username => 'admin')
      subject_sources = CvList.new("subject_source", current_user)
      expect(subject_sources.length).to be > 0
  end
end
