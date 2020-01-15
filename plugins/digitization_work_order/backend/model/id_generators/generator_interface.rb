class GeneratorInterface

  def initialize
    # optional
  end

  def generate(record)
    raise NotImplementedError.new("Subclass must implement this method")
  end

end
