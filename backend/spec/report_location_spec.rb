require 'spec_helper'

describe LocationReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:loc_job) { Job.create_from_json(build(:json_location_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { LocationReport.new({:repo_id => repo.id},
                                loc_job,
                                datab) }
  it 'returns the correct fields for the location report' do
    expect(report.query.first.keys.length).to eq(9)
    expect(report.query.first).to have_key(:location_id)
    expect(report.query.first).to have_key(:location_building)
    expect(report.query.first).to have_key(:location_title)
    expect(report.query.first).to have_key(:location_floor)
    expect(report.query.first).to have_key(:location_room)
    expect(report.query.first).to have_key(:location_area)
    expect(report.query.first).to have_key(:location_barcode)
    expect(report.query.first).to have_key(:location_classification)
    expect(report.query.first).to have_key(:location_coordinate)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('location_report.erb')
  end
  it 'renders the expected report' do
    rend = ReportErbRenderer.new(report,{})
    expect(rend.render(report.template)).to include('Location Report')
    expect(rend.render(report.template)).to include('location_resources_subreport.erb')
  end
end
