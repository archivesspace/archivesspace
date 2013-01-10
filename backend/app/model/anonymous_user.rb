require_relative 'user'

class AnonymousUser

  def username
    nil
  end

  def can?(permission, opts = {})
    false
  end

end
