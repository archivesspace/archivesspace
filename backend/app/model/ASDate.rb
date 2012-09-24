class ASDate < Sequel::Model(:dates)
  include ASModel

  plugin :validation_helpers

  many_to_one :accession
  many_to_one :resource
  many_to_one :archival_object


  def validate
    validates_presence([:expression]) if self[:begin].nil? && self[:end].nil?
    validates_presence([:begin]) if self[:expression].nil? || self[:end]
    validates_presence([:end]) if self[:begin]
    validates_presence([:end_time]) if self[:begin_time]
    super
  end

end
