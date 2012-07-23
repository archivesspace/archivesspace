class UserManager

  def create_user(username, first_name, last_name, auth_source,
                  email = nil, phone = nil, title = nil, department = nil,
                  contact = nil, notes = nil)
    User.create(:username => username,
                :first_name => first_name,
                :last_name => last_name,
                :auth_source => auth_source)
  end


  def get_user(username)
    User[:username => username]
  end


  def create_group(groupid, description)
    Group.create(:group_id => groupid,
                 :description => description)
  end

end
