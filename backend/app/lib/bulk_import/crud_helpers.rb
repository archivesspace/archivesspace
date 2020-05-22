# extension to app/lib/crud_helpers.rb to deal with not having the env hash
require_relative "../../lib/crud_helpers"
module CrudHelpers
  def handle_raw_listing(model, where = {}, current_user)
    dataset = CrudHelpers.scoped_dataset(model, where)
    objs = dataset.respond_to?(:all) ? dataset.all : dataset
    opts = { :calculate_linked_repositories => current_user.can?(:index_system) }

    jsons = model.sequel_to_jsonmodel(objs, opts).map { |json|
      if json.is_a?(JSONModelType)
        json.to_hash(:trusted)
      else
        json
      end
    }
    #   results = resolve_references(jsons, true)
    jsons
  end
end
