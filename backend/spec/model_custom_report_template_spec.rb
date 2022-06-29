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
end
