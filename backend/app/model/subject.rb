class Subject < Sequel::Model(:subjects)
  plugin :validation_helpers
  include ASModel

  many_to_many :archival_objects
end
