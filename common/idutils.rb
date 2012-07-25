module IDUtils

  DELIMITER = "_"

  def self.a_to_s(a)
    a.join(DELIMITER)
  end

  def self.s_to_a(s)
    s.split(DELIMITER)
  end

end
