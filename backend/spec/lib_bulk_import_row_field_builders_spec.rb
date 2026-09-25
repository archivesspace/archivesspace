require "spec_helper"
require_relative "../app/lib/bulk_import/row_field_builders"

describe RowFieldBuilders do
  include RowFieldBuilders

  before(:each) do
    @current_user = User.find(:username => "admin")

    @report = BulkImportReport.new
    @report.new_row(1)

    @date_types = CvList.new('date_type', @current_user)
    @date_labels = CvList.new('date_label', @current_user)
    @date_era = CvList.new('date_era', @current_user)
    @date_calendar = CvList.new('date_calendar', @current_user)
  end

  it 'will not create a date with an invalid date type' do
    date = create_date('creation', '1900', '2000', 'bad_type', nil, nil)

    expect(date).to be nil
    expect(@report.current_row.errors[0]).to start_with("Date type")
  end

  it 'will not create a date with an invalid date label' do
    date = create_date('bad_label', '1900', '2000', nil, nil, nil)

    expect(date).to be nil
    expect(@report.current_row.errors[0]).to start_with("Date label")
  end

  it 'will set date type to inclusive if date type blank' do
    date = create_date('creation', '1900', '2000', nil, nil, nil)

    expect(date['date_type']).to eq('inclusive')
  end

  it 'will set date label to creation if date label blank' do
    date = create_date(nil, '1900', '2000', 'single', nil, nil)

    expect(date['label']).to eq('creation')
  end

  it 'will set era on a date when a valid era value is provided' do
    date = create_date('creation', '1900', '2000', nil, nil, nil, 'ce', nil)

    expect(date['era']).to eq('ce')
    expect(@report.current_row.errors).to be_empty
  end

  it 'will set calendar on a date when a valid calendar value is provided' do
    date = create_date('creation', '1900', '2000', nil, nil, nil, nil, 'gregorian')

    expect(date['calendar']).to eq('gregorian')
    expect(@report.current_row.errors).to be_empty
  end

  it 'will log an error but still return the date when an invalid era is provided' do
    date = create_date('creation', '1900', '2000', nil, nil, nil, 'bad_era', nil)

    expect(date).not_to be nil
    expect(@report.current_row.errors[0]).to include("date era")
  end

  it 'will log an error but still return the date when an invalid calendar is provided' do
    date = create_date('creation', '1900', '2000', nil, nil, nil, nil, 'bad_calendar')

    expect(date).not_to be nil
    expect(@report.current_row.errors[0]).to include("date calendar")
  end

  it "will import a date begin and end for accessrestrict note" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict"=>"Access Restriction note", "p_accessrestrict"=>"1", "b_accessrestrict"=>"2021-10-01", "e_accessrestrict"=>"2021-10-31"}
    handle_notes(ao, hash, false)
    expect(ao['notes']).not_to be_nil
    note = ao['notes'][0]
    expect(note).to have_key('rights_restriction')
    expect(note['rights_restriction']['begin']).to eq('2021-10-01')
    expect(note['rights_restriction']['end']).to eq('2021-10-31')
  end

  it "will not import an accessrestrict note date begin that comes after a date end" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict"=>"Access Restriction note", "p_accessrestrict"=>"1", "b_accessrestrict"=>"2021-10-31", "e_accessrestrict"=>"2021-10-01"}
    expect {
      handle_notes(ao, hash, false)
    }.to raise_error(JSONModel::ValidationException)
  end

  it "will import a date begin and end for userestrict note" do
    ao = create(:json_archival_object)
    hash = {"n_userestrict"=>"Use Restriction note", "p_userestrict"=>"1", "b_userestrict"=>"2021-10-01", "e_userestrict"=>"2021-10-31"}
    handle_notes(ao, hash, false)
    expect(ao['notes']).not_to be_nil
    note = ao['notes'][0]
    expect(note).to have_key('rights_restriction')
    expect(note['rights_restriction']['begin']).to eq('2021-10-01')
    expect(note['rights_restriction']['end']).to eq('2021-10-31')
  end

  it "will not import a userestrict note date begin that comes after a date end" do
    ao = create(:json_archival_object)
    hash = {"n_userestrict"=>"Use Restriction note", "p_userestrict"=>"1", "b_userestrict"=>"2021-10-31", "e_userestrict"=>"2021-10-01"}
    expect {
      handle_notes(ao, hash, false)
    }.to raise_error(JSONModel::ValidationException)
  end

  it "will not import a date begin and end for a non-accessrestrict note" do
    ao = create(:json_archival_object)
    hash = {"n_prefercite"=>"Preferred Citation note", "p_prefercite"=>"1", "b_prefercite"=>"2021-10-01", "e_prefercite"=>"2021-10-31"}
    handle_notes(ao, hash, false)
    expect(ao['notes']).not_to be_nil
    note = ao['notes'][0]
    expect(note).not_to have_key('rights_restriction')
  end

  it "will import a single access restriction type from t_accessrestrict_1" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
            "t_accessrestrict_1" => "RestrictedSpecColl"}
    handle_notes(ao, hash, false)
    note = ao['notes'][0]
    expect(note['rights_restriction']['local_access_restriction_type'])
      .to eq(['RestrictedSpecColl'])
  end

  it "will import multiple access restriction types from t_accessrestrict_1 and t_accessrestrict_2" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
            "t_accessrestrict_1" => "RestrictedSpecColl",
            "t_accessrestrict_2" => "RestrictedCurApprSpecColl"}
    handle_notes(ao, hash, false)
    note = ao['notes'][0]
    expect(note['rights_restriction']['local_access_restriction_type'])
      .to contain_exactly('RestrictedSpecColl', 'RestrictedCurApprSpecColl')
  end

  it "will not create a second accessrestrict note when multiple restriction types are provided" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
            "t_accessrestrict_1" => "RestrictedSpecColl",
            "t_accessrestrict_2" => "RestrictedSpecColl"}
    handle_notes(ao, hash, false)
    expect(ao['notes'].length).to eq(1)
  end

  it "will skip a blank t_accessrestrict_2" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
            "t_accessrestrict_1" => "RestrictedSpecColl",
            "t_accessrestrict_2" => nil}
    handle_notes(ao, hash, false)
    note = ao['notes'][0]
    expect(note['rights_restriction']['local_access_restriction_type'])
      .to eq(['RestrictedSpecColl'])
  end

  it "does not apply accessrestrict dates to a subsequent note in the same row" do
    ao = create(:json_archival_object)
    hash = {
      "n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
      "b_accessrestrict" => "2021-01-01", "e_accessrestrict" => "2021-12-31",
      "n_prefercite" => "Preferred citation", "p_prefercite" => "1",
    }
    handle_notes(ao, hash, false)
    prefercite = ao['notes'].find { |n| n['type'] == 'prefercite' }
    expect(prefercite).not_to have_key('rights_restriction')
  end

  it "will import a single access restriction type from the legacy t_accessrestrict column" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
            "t_accessrestrict" => "RestrictedSpecColl"}
    handle_notes(ao, hash, false)
    note = ao['notes'][0]
    expect(note['rights_restriction']['local_access_restriction_type'])
      .to eq(['RestrictedSpecColl'])
  end

  it "sorts restriction types numerically so t_accessrestrict_10 comes after t_accessrestrict_9" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
            "t_accessrestrict_9" => "RestrictedSpecColl",
            "t_accessrestrict_10" => "RestrictedCurApprSpecColl"}
    handle_notes(ao, hash, false)
    note = ao['notes'][0]
    expect(note['rights_restriction']['local_access_restriction_type'])
      .to eq(['RestrictedSpecColl', 'RestrictedCurApprSpecColl'])
  end

  it "will skip a blank string t_accessrestrict value" do
    ao = create(:json_archival_object)
    hash = {"n_accessrestrict" => "Restricted", "p_accessrestrict" => "1",
            "t_accessrestrict_1" => "RestrictedSpecColl",
            "t_accessrestrict_2" => "  "}
    handle_notes(ao, hash, false)
    note = ao['notes'][0]
    expect(note['rights_restriction']['local_access_restriction_type'])
      .to eq(['RestrictedSpecColl'])
  end
end
