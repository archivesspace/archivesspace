# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree toolbar inline create', js: true do
  context 'Resources' do
    it_behaves_like 'entering inline create and cancelling', InfiniteTreeHierarchyConfigs::RESOURCE
    it_behaves_like 'saving inline creates with Save and Save +1',
                    InfiniteTreeHierarchyConfigs::INLINE_CREATE[:resources]
  end

  context 'Digital Objects' do
    it_behaves_like 'entering inline create and cancelling', InfiniteTreeHierarchyConfigs::DIGITAL_OBJECT
    it_behaves_like 'saving inline creates with Save and Save +1',
                    InfiniteTreeHierarchyConfigs::INLINE_CREATE[:digital_objects]
  end

  context 'Classifications' do
    it_behaves_like 'entering inline create and cancelling', InfiniteTreeHierarchyConfigs::CLASSIFICATION
    it_behaves_like 'saving inline creates with Save and Save +1',
                    InfiniteTreeHierarchyConfigs::INLINE_CREATE[:classifications]
  end
end
