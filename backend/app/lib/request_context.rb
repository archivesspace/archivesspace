class RequestContext

  def self.active?
    !Thread.current[:request_context].nil?
  end


  def self.open(context = {})
    # Stash the original context
    original_context = Thread.current[:request_context]

    # Add in the bits we care about
    Thread.current[:request_context] ||= {}
    Thread.current[:request_context] = Thread.current[:request_context].merge(context)

    begin
      yield
    ensure
      # And restore the old context once done
      Thread.current[:request_context] = original_context
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


  def self.dump
    Thread.current[:request_context].clone
  end

end
