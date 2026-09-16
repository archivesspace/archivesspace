# frozen_string_literal: true

module InfiniteTreeHierarchy
  ROOT_TO_CHILD_TYPE = {
    'resource' => 'archival_object',
    'digital_object' => 'digital_object_component',
    'classification' => 'classification_term'
  }.freeze

  module_function

  # @param root_type [String, Symbol, nil]
  # @return [String, nil] child jsonmodel type, or nil when unknown
  def child_type_for(root_type)
    return nil if root_type.nil?

    ROOT_TO_CHILD_TYPE[root_type.to_s]
  end

  # @return [Hash]
  def as_json(_options = nil)
    ROOT_TO_CHILD_TYPE.transform_values { |child_type| { 'childType' => child_type } }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
