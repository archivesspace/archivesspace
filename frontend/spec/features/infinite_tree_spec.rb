require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree', js: true do
  RECORD_TYPE_CONFIGS = {
    resources: {
      record_type: 'resource',
      child_type: 'archival_object',
      root_factory: :resource,
      child_factory: :archival_object,
      root_relationship_key: :resource,
      show_path: ->(id) { "/resources/#{id}" },
      columns: {
        base: ['title', 'level', 'type', 'container'],
        conditional: {
          identifier: 'display_identifiers_in_largetree_container'
        }
      },
      supports_mixed_content: true,
      supports_suppression: true,
      max_batch_scenarios: 4,
      additional_root_attrs: {},
      additional_child_attrs: {}
    },
    digital_objects: {
      record_type: 'digital_object',
      child_type: 'digital_object_component',
      root_factory: :digital_object,
      child_factory: :digital_object_component,
      root_relationship_key: :digital_object,
      show_path: ->(id) { "/digital_objects/#{id}" },
      columns: {
        base: ['title', 'type', 'file_uri']
      },
      supports_mixed_content: true,
      supports_suppression: true,
      max_batch_scenarios: 2,
      additional_root_attrs: { digital_object_type: 'mixed_materials' },
      additional_child_attrs: {}
    },
    classifications: {
      record_type: 'classification',
      child_type: 'classification_term',
      root_factory: :classification,
      child_factory: :classification_term,
      root_relationship_key: :classification,
      show_path: ->(id) { "/classifications/#{id}" },
      columns: {
        base: ['title']
      },
      supports_mixed_content: false,
      supports_suppression: false,
      max_batch_scenarios: 2,
      additional_root_attrs: ->(uid) { { identifier: "CLASS-#{uid}" } },
      additional_child_attrs: ->(uid) { { identifier: "CT-#{uid}" } }
    }
  }.freeze

  RECORD_TYPE_CONFIGS.each do |record_type, config|
    context "on the #{record_type.to_s.humanize.titleize} show view" do
      it_behaves_like 'infinite tree record show view', config
    end
  end
end
