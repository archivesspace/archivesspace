module ASpaceHelpers
  include Capybara::DSL
  include TestUtils::SpecBatchCreate

  # Creates `count` published archival objects under `parent` (or at the top
  # level of `resource`) with a single batch import request.  See
  # TestUtils::SpecBatchCreate#batch_create_tree_children.
  def batch_create_archival_objects(count, resource:, parent: nil, **values, &block)
    batch_create_tree_children(:archival_object, count, root_key: :resource, root: resource, parent: parent,
                               publish: true, **values, &block)
  end
end
