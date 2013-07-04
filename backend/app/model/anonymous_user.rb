class AnonymousUser

  def anonymous?
    true
  end


  def username
    nil
  end


  def can?(permission, opts = {})
    false
  end

end
