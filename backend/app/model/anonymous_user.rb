require_relative 'user'

class AnonymousUser

  def can?(permission, opts = {}, next_check)
    false
  end

end
