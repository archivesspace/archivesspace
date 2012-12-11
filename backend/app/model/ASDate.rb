class ASDate < Sequel::Model(:date)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:date)


  def validate
    if self[:date_type] === "expression"
      validates_presence([:expression])
    elsif self[:date_type] === "single"
       validates_presence([:begin])
    elsif self[:date_type] === "bulk" || self[:date_type] === "inclusive"
      validates_presence([:begin])
      validates_presence([:end])
      validates_presence([:begin_time]) if self[:end_time]
      validates_presence([:end_time]) if self[:begin_time]
    end
    super
  end


end
