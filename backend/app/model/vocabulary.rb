class Vocabulary < Sequel::Model(:vocabularies)
  plugin :validation_helpers
  include ASModel

  one_to_many :subjects

  def self.set(params)
    self.where(params)
  end

end
