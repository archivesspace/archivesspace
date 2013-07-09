class Permissions

  def self.pack(repo_permissions_map)
    permission_set = repo_permissions_map.values.flatten.uniq

    result = {}
    result['key'] = permission_set

    result['perms'] = Hash[repo_permissions_map.map do |repo_uri, granted_permissions|

                             packed_permissions = permission_set.map {|permission|
                               granted_permissions.include?(permission) ? "1" : "0"
                             }.join("")

                             [repo_uri, packed_permissions]
                           end]

    result
  end


  def self.user_can?(packed_permission_map, repo_uri, permission)
    position = packed_permission_map['key'].index(permission)

    if !position
      # Any permission not in our key list isn't granted in any repo
      return false
    end

    # Otherwise, the permission is granted if there's a "1" in the appropriate
    # position
    packed_permissions = packed_permission_map['perms'][repo_uri]
    packed_permissions && packed_permissions[position] == "1"
  end

end
