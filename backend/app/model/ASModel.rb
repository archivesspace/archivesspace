require_relative '../lib/realtime_indexing'

require_relative 'ASModel_crud'
require_relative 'ASModel_transfers'
require_relative 'ASModel_database_mapping'
require_relative 'ASModel_sequel'
require_relative 'ASModel_scoping'
require_relative 'ASModel_object_graph'
require 'date'

module ASModel
  include JSONModel

  @@all_models = []

  def self.all_models
    @@all_models
  end

  def self.included(base)
    base.instance_eval do
      plugin :optimistic_locking
      plugin :validation_helpers
    end

    # Turn off the 'after_commit' and 'after_rollback' hooks on Sequel::Model.
    # We don't use them anywhere, and they would otherwise cause a pair of
    # blocks to be stored in memory every time we call '.save' (which in turn
    # capture the record being saved and stop it being GC'd until the
    # transaction finally commits).  When we're doing large batch imports (and
    # committing at the end) that's a lot of memory!
    base.use_after_commit_rollback = false

    base.extend(JSONModel)

    base.include(CRUD)
    base.include(RepositoryTransfers)
    base.include(DatabaseMapping)
    base.include(SequelHooks)
    base.include(ModelScoping)
    base.include(ObjectGraph)

    @@all_models << base
  end

end


require_relative 'mixins/dynamic_enums'
