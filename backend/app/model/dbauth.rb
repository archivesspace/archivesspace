require 'bcrypt'

class DBAuth

  include BCrypt

  def self.set_password(username, password)
    pwhash = Password.create(password)
    username = username.downcase

    DB.open do |db|
      DB.attempt {
        db[:auth_db].insert(:username => username,
                            :pwhash => pwhash,
                            :create_time => Time.now,
                            :last_modified => Time.now)
      }.and_if_constraint_fails {
        db[:auth_db].
        filter(:username => username).
        update(:username => username,
               :pwhash => pwhash,
               :last_modified => Time.now)
      }
    end
  end


  def self.authenticate(username, password, callback)
    username = username.downcase

    DB.open do |db|
      pwhash = db[:auth_db].filter(:username => username).get(:pwhash)

      if pwhash and (Password.new(pwhash) == password)
        user = User.find(:username => username)

        callback.call(user.name)
      else
        nil
      end

    end
  end
end
