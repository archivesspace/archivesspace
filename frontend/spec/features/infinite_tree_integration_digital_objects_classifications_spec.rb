# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Integration for Digital Objects and Classifications', js: true do
  DIGITAL_OBJECT_INTEGRATION_CONFIG = {
    root_type: 'digital_object',
    child_type: 'digital_object_component',
    root_factory: :digital_object,
    child_factory: :digital_object_component,
    root_relationship_key: :digital_object,
    root_dirty_field: 'digital_object_title_',
    child_dirty_field: 'digital_object_component_component_id_',
    child_revert_field: 'digital_object_component_title_',
    child_save_field: 'digital_object_component_component_id_',
    child_save_value: 'updated component id',
    child_post_save_field: 'digital_object_component_title_'
  }.freeze

  CLASSIFICATION_INTEGRATION_CONFIG = {
    root_type: 'classification',
    child_type: 'classification_term',
    root_factory: :classification,
    child_factory: :classification_term,
    root_relationship_key: :classification,
    root_dirty_field: 'classification_title_',
    child_dirty_field: 'classification_term_identifier_',
    child_revert_field: 'classification_term_title_',
    child_save_field: 'classification_term_identifier_',
    child_save_value: 'updated identifier',
    child_post_save_field: 'classification_term_title_'
  }.freeze

  context 'Digital Objects' do
    it_behaves_like 'infinite tree integration edit parity', DIGITAL_OBJECT_INTEGRATION_CONFIG
  end

  context 'Classifications' do
    it_behaves_like 'infinite tree integration edit parity', CLASSIFICATION_INTEGRATION_CONFIG
  end
end
