require 'spec_helper'
require_relative 'factories'

describe 'Custom Report Template model' do

  it 'can create a custom report template' do
    template = JSONModel(:custom_report_template).from_hash(
                          {"name": "Template of identifiers",
                           "limit": 10,
                           "data": {fields: {identifier: {include: 1}}}.to_json
                          })

    expect {
      CustomReportTemplate.create_from_json(template) }.not_to raise_error
  end

  it 'rejects a template with only one narrow by date' do
    template = JSONModel(:custom_report_template).from_hash(
                          {"name": "Template with bad dates",
                           "limit": 10,
                           "data": {fields: {create_time: {include: 1, range_start: "2014-06-12"}}}.to_json
                          })

    expect {
      CustomReportTemplate.create_from_json(template) }.to raise_error(Sequel::ValidationFailed)
  end

  it 'displays human-readable enum values for subject source filter' do
    # Create a test repository for the custom report template
    repo = create(:repo, repo_code: "test_enum_#{Time.now.to_i}")
    RequestContext.put(:repo_id, repo.id)
    JSONModel.set_repository(repo.id)
    
    # Get some enum values for subjects
    # Create enumerations and values for testing
    subject_source_enum = Enumeration.find(name: 'subject_source')
    enum_values = subject_source_enum.enumeration_value.reject { |v| v.suppressed == 1 }.first(2)
    
    # Create a custom report template with subject source filter
    template_data = {
      "custom_record_type" => "subject",
      "fields" => {
        "title" => {"include" => "1"},
        "source" => {
          "include" => "1",
          "values" => enum_values.map(&:id)
        }
      }
    }
    
    template = JSONModel(:custom_report_template).from_hash({
      "name" => "Subject Report with Source Filter #{Time.now.to_i}",
      "limit" => 10,
      "data" => template_data.to_json
    })
    
    template_id = CustomReportTemplate.create_from_json(template).id
    
    # Create a mock job
    mock_job = double('Job')
    allow(mock_job).to receive(:write_output)
    
    # Create the custom report
    report = CustomReport.new({'template' => template_id.to_s, :repo_id => repo.id}, mock_job, $testdb)
    
    # Verify that the enum filter information shows human-readable values
    source_filter = report.info["source"]
    expect(source_filter).to be_a(String)
    expect(source_filter).not_to match(/^\d+/)  # Should not start with numeric IDs
    
    # Verify it contains translated enum values
    enum_values.each do |enum_val|
      translated_value = I18n.t("enumerations.subject_source.#{enum_val.value}", :default => enum_val.value)
      expect(source_filter).to include(translated_value)
    end
    
    # Verify it does not contain raw numeric IDs
    enum_values.each do |enum_val|
      expect(source_filter).not_to include(enum_val.id.to_s)
    end
  end

  it 'displays human-readable enum values for accession acquisition_type filter' do
    # Create a test repository for the custom report template  
    repo = create(:repo, repo_code: "test_accession_enum_#{Time.now.to_i}")
    RequestContext.put(:repo_id, repo.id)
    JSONModel.set_repository(repo.id)
    
    # Get some enum values for accession acquisition type
    acquisition_type_enum = Enumeration.find(:name => 'accession_acquisition_type')
    enum_values = acquisition_type_enum.enumeration_value.reject { |v| v.suppressed == 1 }.first(2)
    
    # Create a custom report template with acquisition type filter
    template_data = {
      "custom_record_type" => "accession",
      "fields" => {
        "title" => {"include" => "1"},
        "acquisition_type" => {
          "include" => "1", 
          "values" => enum_values.map(&:id)
        }
      }
    }
    
    template = JSONModel(:custom_report_template).from_hash({
      "name" => "Accession Report with Acquisition Type Filter #{Time.now.to_i}",
      "limit" => 10,
      "data" => template_data.to_json
    })
    
    template_id = CustomReportTemplate.create_from_json(template).id
    
    # Create a mock job
    mock_job = double('Job')
    allow(mock_job).to receive(:write_output)
    
    # Create the custom report
    report = CustomReport.new({'template' => template_id.to_s, :repo_id => repo.id}, mock_job, $testdb)
    
    # Verify that the enum filter information shows human-readable values
    acquisition_filter = report.info["acquisition_type"]
    expect(acquisition_filter).to be_a(String)
    expect(acquisition_filter).not_to match(/^\d+/)  # Should not start with numeric IDs
    
    # Verify it contains translated enum values
    enum_values.each do |enum_val|
      translated_value = I18n.t("enumerations.accession_acquisition_type.#{enum_val.value}", :default => enum_val.value)
      expect(acquisition_filter).to include(translated_value)
    end
    
    # Verify it does not contain raw numeric IDs
    enum_values.each do |enum_val|
      expect(acquisition_filter).not_to include(enum_val.id.to_s)
    end
  end
end
