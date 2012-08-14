class Vocabulary < Sequel::Model(:vocabularies)
  plugin :validation_helpers
  include ASModel

  one_to_many :subjects
  
  def self.set(params)
    if params.is_a?(Hash)
      self.where(params)
    else
      self.all
    end
  end
  
end
