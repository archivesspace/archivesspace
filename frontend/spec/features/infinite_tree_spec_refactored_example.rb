require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree', js: true do
  BATCH_SIZE = Rails.configuration.infinite_tree_batch_size

  # Base shared_examples have been moved to spec/support/shared_examples/infinite_tree_base_shared_examples.rb
  # Control which record types to test by commenting/uncommenting in infinite_tree_spec_helpers.rb

  InfiniteTreeSpecHelpers::RECORD_CONFIGS.each do |record_name, config|
    context "on the #{record_name.to_s.humanize.downcase} show view" do
      it_behaves_like 'infinite tree record show view', config
    end
  end
end
