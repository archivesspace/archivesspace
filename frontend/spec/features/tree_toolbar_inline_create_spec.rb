# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Tree toolbar inline create', js: true do
  context 'Resources' do
    it_behaves_like 'entering inline create and cancelling', TreeHierarchyConfigs::RESOURCE
    it_behaves_like 'saving inline creates with Save and Save +1',
                    TreeHierarchyConfigs::INLINE_CREATE[:resources]
  end

  context 'Digital Objects' do
    it_behaves_like 'entering inline create and cancelling', TreeHierarchyConfigs::DIGITAL_OBJECT
    it_behaves_like 'saving inline creates with Save and Save +1',
                    TreeHierarchyConfigs::INLINE_CREATE[:digital_objects]
  end

  context 'Classifications' do
    it_behaves_like 'entering inline create and cancelling', TreeHierarchyConfigs::CLASSIFICATION
    it_behaves_like 'saving inline creates with Save and Save +1',
                    TreeHierarchyConfigs::INLINE_CREATE[:classifications]
  end
end
