require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree', js: true do
  InfiniteTreeHierarchyConfigs::READ_ONLY.each do |record_type, config|
    context "on the #{record_type.to_s.humanize.titleize} show view" do
      it_behaves_like 'having an infinite tree on the read-only view', config
    end
  end
end
