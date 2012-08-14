class Subject < Sequel::Model(:subjects)
  plugin :validation_helpers
  include ASModel


  def validate
    super
    validates_presence(:term_type, :message=>"You must supply a term type")
    validates_unique(:term, :message=>"Term must be unique")
  end

  many_to_many :archival_objects
end
