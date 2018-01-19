class ConflictException < StandardError
  attr_reader :conflicts

  def initialize(conflicts)
    @conflicts = conflicts
    super
  end
end

class AccessDeniedException < StandardError; end
class RecordNotFound < StandardError; end
class LoginFailedException < StandardError; end
class RequestFailedException < StandardError; end
