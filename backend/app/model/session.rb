require 'securerandom'

class Session

  SESSION_ID_LENGTH = 32

  attr_reader :id


  def initialize(sid = nil)
    DB.open do |db|

      if not sid
        while true
          sid = SecureRandom.hex(SESSION_ID_LENGTH)

          begin
            db[:sessions].insert(:session_id => sid,
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
      end


      @id = sid

      session_data = db[:sessions].filter(:session_id => sid).get(:session_data)
      @store = Marshal.load(session_data.unpack("m*").first)
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
      db[:sessions]
        .filter(:session_id => @id)
        .update(:session_data => [Marshal.dump(@store)].pack("m*"),
                :last_modified => Time.now)
    end
  end

end
