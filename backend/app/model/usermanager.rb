class UserManager

  def create_user(username, first_name, last_name, auth_source,
                  email = nil, phone = nil, title = nil, department = nil,
                  contact = nil, notes = nil)
    DB.open do |db|
      db[:users].insert(:username => username,
                        :first_name => first_name,
                        :last_name => last_name,
                        :auth_source => auth_source,
                        :create_time => Time.now,
                        :last_modified => Time.now)
    end
  end


  def get_user(username)
    DB.open do |db|
      db[:users].filter(:username => username).first()
    end
  end


  def create_group(groupid, description)
    DB.open do |db|
      db[:groups].insert(:group_id => groupid,
                         :description => description,
                         :create_time => Time.now,
                         :last_modified => Time.now)
    end
  end


  def assign_user_to_group(username, group_id)
    DB.open do |db|
      begin
        db[:user_groups].insert(:username => username,
                                :group_id => group_id)
      rescue Sequel::DatabaseError => ex
        if DB.is_integrity_violation(ex)
          # Harmless in this case.  Just means they were already in the
          # requested group.
        end
      end
    end
  end


end
