# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ExportHelper do
  before :all do
    @repo = create :repo, repo_code: "exporthelper_test_#{Time.now.to_i}"
    set_repo @repo
  end

  it 'can convert the ancestor refs from a search to a user-friendly context column for CSV downloads' do
    collection = create(:resource, title: 'ExportHelper collection', level: 'collection')
    series = create(:archival_object, title: 'ExportHelper series', level: 'series', resource: {ref: collection.uri})
    top_container = create(:top_container, type: 'box')
    item = create(:archival_object,
      title: 'ExportHelper item',
      level: 'item',
      resource: {ref: collection.uri}, parent: {ref: series.uri}
    )
    digital_object = create(:digital_object, title: 'ExportHelper digital object')
    digital_object_component = create(:digital_object_component, title: 'ExportHelper digital object component', digital_object: {ref: digital_object.uri})

    run_index_round

    criteria = {'fields[]' => ['primary_type', 'title', 'ancestors'], 'q' => '*', 'page' => '1'}
    export = csv_export_with_context "#{@repo.uri}/search", Search.build_filters(criteria)
    expect(export).to include('archival_object,ExportHelper series,ExportHelper collection')
    expect(export).to include('archival_object,ExportHelper item,ExportHelper collection > ExportHelper series')
    expect(export).to include('digital_object_component,ExportHelper digital object component,ExportHelper digital object')
  end
end
