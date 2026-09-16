# frozen_string_literal: true

# Stable hierarchy identity and capability flags for Infinite Tree feature specs.
# Concern-specific keys (form fields, flash lambdas, etc.) live beside their shared examples.

module InfiniteTreeHierarchyConfigs
  RESOURCE = {
    root_type: 'resource',
    child_type: 'archival_object',
    root_factory: :resource,
    child_factory: :archival_object,
    root_relationship_key: :resource,
    supports_mixed_content: true,
    supports_suppression: true,
    supports_bulk_import: true,
    supports_rde: true,
    supports_add_duplicate: true,
    max_batch_scenarios: 4
  }.freeze

  DIGITAL_OBJECT = {
    root_type: 'digital_object',
    child_type: 'digital_object_component',
    root_factory: :digital_object,
    child_factory: :digital_object_component,
    root_relationship_key: :digital_object,
    supports_mixed_content: true,
    supports_suppression: true,
    supports_bulk_import: false,
    supports_rde: true,
    supports_add_duplicate: false,
    max_batch_scenarios: 2,
    additional_root_attrs: { digital_object_type: 'mixed_materials' }
  }.freeze

  CLASSIFICATION = {
    root_type: 'classification',
    child_type: 'classification_term',
    root_factory: :classification,
    child_factory: :classification_term,
    root_relationship_key: :classification,
    supports_mixed_content: false,
    supports_suppression: false,
    supports_bulk_import: false,
    supports_rde: false,
    supports_add_duplicate: false,
    max_batch_scenarios: 2,
    additional_root_attrs: ->(uid) { { identifier: "CLASS-#{uid}" } },
    additional_child_attrs: ->(uid) { { identifier: "CT-#{uid}" } }
  }.freeze

  READ_ONLY = {
    resources: RESOURCE.merge(
      record_type: 'resource',
      show_path: ->(id) { "/resources/#{id}" },
      columns: {
        base: %w[title level type container],
        conditional: { identifier: 'display_identifiers_in_largetree_container' }
      },
      additional_root_attrs: {},
      additional_child_attrs: {}
    ),
    digital_objects: DIGITAL_OBJECT.merge(
      record_type: 'digital_object',
      show_path: ->(id) { "/digital_objects/#{id}" },
      columns: { base: %w[title type file_uri] },
      additional_child_attrs: {}
    ),
    classifications: CLASSIFICATION.merge(
      record_type: 'classification',
      show_path: ->(id) { "/classifications/#{id}" },
      columns: { base: ['title'] }
    )
  }.freeze

  INTEGRATION = {
    resources: RESOURCE.merge(
      run_indexer: false,
      root_dirty_field: 'resource_title_',
      child_dirty_field: 'archival_object_component_id_',
      child_revert_field: 'archival_object_title_',
      child_save_field: 'archival_object_component_id_',
      child_save_value: 'updated component id',
      child_post_save_field: 'archival_object_title_'
    ),
    digital_objects: DIGITAL_OBJECT.merge(
      run_indexer: true,
      root_dirty_field: 'digital_object_title_',
      child_dirty_field: 'digital_object_component_component_id_',
      child_revert_field: 'digital_object_component_title_',
      child_save_field: 'digital_object_component_component_id_',
      child_save_value: 'updated component id',
      child_post_save_field: 'digital_object_component_title_'
    ),
    classifications: CLASSIFICATION.merge(
      run_indexer: true,
      root_dirty_field: 'classification_title_',
      child_dirty_field: 'classification_term_identifier_',
      child_revert_field: 'classification_term_title_',
      child_save_field: 'classification_term_identifier_',
      child_save_value: 'updated identifier',
      child_post_save_field: 'classification_term_title_'
    )
  }.freeze

  REORDER = {
    digital_objects: DIGITAL_OBJECT,
    classifications: CLASSIFICATION
  }.freeze

  INLINE_CREATE = {
    resources: RESOURCE.merge(
      expected_plain_save_flash: lambda { |child_title, root_title|
        "Archival Object #{child_title} on Resource #{root_title} created"
      },
      expected_validation_pattern: /Level|Title|Date/m,
      fill_invalid_fields: :fill_invalid_archival_object_fields
    ),
    digital_objects: DIGITAL_OBJECT.merge(
      expected_plain_save_flash: lambda { |child_title, root_title|
        "Digital Object Component #{child_title} created on Digital Object #{root_title}"
      },
      expected_validation_pattern: /Label.*Title.*Date/m,
      fill_invalid_fields: :fill_invalid_digital_object_component_fields
    ),
    classifications: CLASSIFICATION.merge(
      expected_plain_save_flash: lambda { |child_title, _root_title|
        "Classification Term #{child_title} created"
      },
      expected_validation_pattern: nil,
      fill_invalid_fields: :fill_invalid_classification_term_fields
    )
  }.freeze
end
