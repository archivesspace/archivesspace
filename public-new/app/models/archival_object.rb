class ArchivalObject < Record

  def initialize(*args)
    super
  end

  def finding_aid
    # as this shares the same template as resources,
    # be clear that this object doesn't have a finding aid
    nil
  end

  private
end