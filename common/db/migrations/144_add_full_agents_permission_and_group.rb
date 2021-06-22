require_relative 'utils'

Sequel.migration do
  $stderr.puts("Creating Permission and Group for Show Full Agents")

  up do
    show_full_agents_permission_id = self[:permission]
      .insert(:permission_code => 'show_full_agents',
              :description => 'The ability to add and edit extended agent attributes',
              :level => 'repository',
              :created_by => 'admin',
              :last_modified_by => 'admin',
              :create_time => Time.now,
              :system_mtime => Time.now,
              :user_mtime => Time.now)

    $stderr.puts("Adding Show Full Agents Permission to existing Manager and Archivist Groups")
    # add this permission to all manager and archivist groups
    self[:group]
      .filter(:group_code => "repository-managers")
      .select(:id)
      .each do |m|
      self[:group_permission].insert(
        :group_id      => m[:id],
        :permission_id => show_full_agents_permission_id
      )
    end

    self[:group]
      .filter(:group_code => "repository-archivists")
      .select(:id)
      .each do |m|
      self[:group_permission].insert(
        :group_id      => m[:id],
        :permission_id => show_full_agents_permission_id
      )
    end
  end

  down do
  end

end
