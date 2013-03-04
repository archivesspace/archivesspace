class Username
  def self.value(s)
    s = s.downcase.strip

    if s !~ /\A[a-zA-Z0-9\-_. ]+\z/ || s =~ /  +/
      raise InvalidUsernameException.new
    end

    s
  end
end
