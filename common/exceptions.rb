class AccessDeniedException < StandardError
end


class ConflictException < StandardError
  attr_reader :conflicts

  def initialize(conflicts)
    @conflicts = conflicts
    super
  end
end

class RecordNotFound < StandardError
end
