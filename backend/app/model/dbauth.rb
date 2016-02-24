require 'bcrypt'

class DBAuth

  extend JSONModel
  include BCrypt

  def self.set_password(username, password)
    pwhash = Password.create(password)
    username = username.downcase

    DB.open do |db|
      DB.attempt {
        db[:auth_db].insert(:username => username,
                            :pwhash => pwhash,
                            :create_time => Time.now,
                            :system_mtime => Time.now)
      }.and_if_constraint_fails {
        db[:auth_db].
        filter(:username => username).
        update(:username => username,
               :pwhash => pwhash,
               :system_mtime => Time.now)
      }
    end
  end


  def self.authenticate(username, password)
    username = username.downcase

    DB.open do |db|
      pwhash = db[:auth_db].filter(:username => username).get(:pwhash)

      if pwhash and (Password.new(pwhash) == password)
       user = User.find(:username => username)
       JSONModel(:user).from_hash(
        :username => username,
        :name => user.name,
        :email => user.email,
        :first_name => user.first_name,
        :last_name => user.last_name,
        :telephone => user.telephone,
        :title => user.title,
        :department => user.department,
        :additional_contact => user.additional_contact
       )
    else
      nil
    end
  end
end


  def self.matching_usernames(query)
    DB.open do |db|
      query = query.gsub(/[%]/, '').downcase
      db[:auth_db].left_outer_join(:user, :username => :username).
                   filter(Sequel.~(:is_system_user => 1)).
                   filter(Sequel.like(Sequel.function(:lower, :auth_db__username),
                                      "#{query}%")).
        select(:auth_db__username).
        limit(AppConfig[:max_usernames_per_source].to_i).
        map {|row| row[:username]}
    end
  end


  def self.delete_user(username)
    DB.open do |db|
      db[:auth_db].filter(:username => username).delete
    end
  end

end
