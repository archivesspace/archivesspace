# Helper methods for Infinite Tree specs to reduce data setup duplication

module InfiniteTreeSpecHelpers
  # Record configurations for different types
  # Comment out record types you don't want to test
  RECORD_CONFIGS = {
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
        base: ['title', 'type', 'container']
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

  # Create multiple children for a given parent record
  def create_children_for_parent(parent, count, child_factory, relationship_keys, title_prefix = nil, additional_attrs = {})
    count.times.map do |i|
      create(child_factory, {
        relationship_keys[:root] => { 'ref' => relationship_keys[:root_record].uri },
        parent: { 'ref' => parent.uri },
        title: "#{title_prefix || 'Child'} #{i + 1} #{Time.now.to_i}"
      }.merge(additional_attrs))
    end
  end

  # Create multiple children for a root record (no parent)
  def create_children_for_root(root, count, child_factory, relationship_key, title_prefix = nil, additional_attrs = {})
    (count - 1).times.map do |i| # -1 because usually one child already exists in the context
      create(child_factory, {
        relationship_key => { 'ref' => root.uri },
        title: "#{title_prefix || 'Child'} #{i + 1} #{Time.now.to_i}"
      }.merge(additional_attrs))
    end
  end

  # Standardized data setup for page load tests with specific batch configurations
  def setup_batch_data_for_record_type(config, timestamp)
    root_factory = config[:root_factory]
    child_factory = config[:child_factory]
    root_relationship_key = config[:root_relationship_key]
    additional_root_attrs = config[:additional_root_attrs]
    additional_child_attrs = config[:additional_child_attrs]

    # Evaluate Proc-based attrs per invocation (avoid merging a Proc)
    additional_root_attrs = additional_root_attrs.respond_to?(:call) ? additional_root_attrs.call("batch_#{timestamp}") : (additional_root_attrs || {})
    additional_child_attrs = additional_child_attrs.respond_to?(:call) ? additional_child_attrs.call("batch_#{timestamp}") : (additional_child_attrs || {})

    # Create multiple root records for different batch scenarios
    roots = create_multiple_roots(root_factory, timestamp, additional_root_attrs)

    # Create children with different batch counts for each root
    create_batch_children_for_roots(roots, child_factory, root_relationship_key, timestamp, additional_child_attrs)

    roots
  end

  private

  def create_multiple_roots(factory, timestamp, additional_attrs)
    roots = {}

    # Create roots with different child counts
    roots[:single_child] = create(factory, {
      title: "#{factory.to_s.humanize} Single Child #{timestamp}",
      publish: true
    }.merge(additional_attrs))

    roots[:multiple_children] = create(factory, {
      title: "#{factory.to_s.humanize} Multiple Children #{timestamp}",
      publish: true
    }.merge(additional_attrs))

    roots[:two_batches] = create(factory, {
      title: "#{factory.to_s.humanize} Two Batches #{timestamp}",
      publish: true
    }.merge(additional_attrs))

    roots[:three_batches] = create(factory, {
      title: "#{factory.to_s.humanize} Three Batches #{timestamp}",
      publish: true
    }.merge(additional_attrs))

    roots[:four_batches] = create(factory, {
      title: "#{factory.to_s.humanize} Four Batches #{timestamp}",
      publish: true
    }.merge(additional_attrs))

    roots
  end

  def create_batch_children_for_roots(roots, child_factory, root_relationship_key, timestamp, additional_attrs)
    batch_size = Rails.configuration.infinite_tree_batch_size

    create(child_factory, {
      root_relationship_key => { 'ref' => roots[:single_child].uri },
      title: "Single child #{timestamp}",
      publish: true
    }.merge(additional_attrs))

    5.times do |i|
      create(child_factory, {
        root_relationship_key => { 'ref' => roots[:multiple_children].uri },
        title: "Child #{i + 1} #{timestamp}",
        publish: true
      }.merge(additional_attrs))
    end

    (batch_size + 1).times do |i|
      create(child_factory, {
        root_relationship_key => { 'ref' => roots[:two_batches].uri },
        title: "Two batch child #{i + 1} #{timestamp}",
        publish: true
      }.merge(additional_attrs))
    end

    (batch_size * 2 + 1).times do |i|
      create(child_factory, {
        root_relationship_key => { 'ref' => roots[:three_batches].uri },
        title: "Three batch child #{i + 1} #{timestamp}",
        publish: true
      }.merge(additional_attrs))
    end

    (batch_size * 3 + 1).times do |i|
      create(child_factory, {
        root_relationship_key => { 'ref' => roots[:four_batches].uri },
        title: "Four batch child #{i + 1} #{timestamp}",
        publish: true
      }.merge(additional_attrs))
    end
  end
end

# Include the helpers in RSpec
RSpec.configure do |config|
  config.include InfiniteTreeSpecHelpers
end
