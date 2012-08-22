class BadParamsException < StandardError
  attr_accessor :params

  def initialize(params)
    @params = params
  end
end

class ConflictException < StandardError
  attr_reader :conflicts

  def initialize(conflicts)
    @conflicts = conflicts
  end
end

class NotFoundException < StandardError
end
