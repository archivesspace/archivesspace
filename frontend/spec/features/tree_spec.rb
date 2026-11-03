require 'spec_helper'
require 'rails_helper'

describe 'Tree', js: true do
  TreeHierarchyConfigs::READ_ONLY.each do |record_type, config|
    context "on the #{record_type.to_s.humanize.titleize} show view" do
      it_behaves_like 'having a tree on the read-only view', config
    end
  end
end
