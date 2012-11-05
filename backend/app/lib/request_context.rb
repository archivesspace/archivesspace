class RequestContext

  def self.active?
    !Thread.current[:request_context].nil?
  end


  def self.open(context = {})
    set_context = Thread.current[:request_context].nil?

    if set_context
      Thread.current[:request_context] = context
    end

    begin
      yield
    ensure
      if set_context
        Thread.current[:request_context] = nil
      end
    end
  end


  def self.put(key, val)
    Thread.current[:request_context][key] = val
  end


  def self.get(key)
    if Thread.current[:request_context]
      Thread.current[:request_context][key]
    end
  end

end
