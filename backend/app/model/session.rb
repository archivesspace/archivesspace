require 'securerandom'

class Session

  SESSION_ID_LENGTH = 32

  attr_reader :id


  def initialize(sid = nil, store = nil)
    if not sid
      # Create a new session in the DB
      DB.open do |db|

        while true
          sid = SecureRandom.hex(SESSION_ID_LENGTH)

          begin
            db[:session].insert(:session_id => sid,
                                :session_data => [Marshal.dump({})].pack("m*"),
                                :last_modified => Time.now)
            break
          rescue Sequel::DatabaseError => ex
            if not DB.is_integrity_violation(ex)
              raise ex
            end

            # Otherwise, retry with a different session ID.
          end
        end

        @id = sid
        @store = {}
      end
    else
      @id = sid
      @store = store
    end
  end


  def self.find(sid)
    DB.open do |db|
      session_data = db[:session].filter(:session_id => sid).get(:session_data)

      if session_data
        Session.new(sid, Marshal.load(session_data.unpack("m*").first))
      else
        nil
      end
    end
  end


  def self.expire(sid)
    DB.open do |db|
      db[:session].filter(:session_id => sid).delete
    end
  end


  def []=(key, val)
    @store[key] = val
  end


  def [](key)
    return @store[key]
  end


  def save
    DB.open do |db|
      db[:session]
        .filter(:session_id => @id)
        .update(:session_data => [Marshal.dump(@store)].pack("m*"),
                :last_modified => Time.now)
    end
  end


  def touch
    DB.open do |db|
      db[:session]
        .filter(:session_id => @id)
        .update(:last_modified => Time.now)
    end
  end


  def age
    last_modified = 0
    DB.open do |db|
      last_modified = db[:session]
        .filter(:session_id => @id)
        .get(:last_modified)
    end
    (Time.now - last_modified).to_i
  end

end
