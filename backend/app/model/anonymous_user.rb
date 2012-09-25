require_relative 'user'

class AnonymousUser

  def can?(permission, opts = {})
    false
  end

end
