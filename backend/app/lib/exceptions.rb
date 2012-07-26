class MissingParamsException < StandardError
end

class ConflictException < StandardError
  attr_reader :conflicts

  def initialize(conflicts)
    @conflicts = conflicts
  end
end

class NotFoundException < StandardError
end
