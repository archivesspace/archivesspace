class Vocabulary < Sequel::Model(:vocabularies)
  plugin :validation_helpers
  include ASModel

  one_to_many :subjects
end
