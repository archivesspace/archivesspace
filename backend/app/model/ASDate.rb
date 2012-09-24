class ASDate < Sequel::Model(:dates)
  include ASModel

  plugin :validation_helpers

  many_to_one :accession
  many_to_one :resource
  many_to_one :archival_object


  def validate
    if self[:date_type] === "expression"
      validates_presence([:expression])
    elsif self[:date_type] === "single"
       validates_presence([:begin])
    elsif self[:date_type] === "bulk" || self[:date_type] === "inclusive"
      validates_presence([:begin])
      validates_presence([:end])
      validates_presence([:end_time]) if self[:begin_time]
    end
    super
  end


end
