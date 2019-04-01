
class UserGroupsReport < AbstractReport

  register_report


  def query_string

    "SELECT id,username as identifier,name,department,title as user_title,email,telephone,source,is_system_user,is_hidden_user from user"
    
  end


  def fix_row(row)

    user_id = row[:id]
    nbsp = '   '

    if format == 'pdf' || format == 'html'
      row[:source] = row[:source] + nbsp * 12
      row[:source] = row[:source] + " SYSTEM_USER " + nbsp * 8 if row[:is_system_user] != 0
      row[:source] = row[:source] + " HIDDEN_USER " if row[:is_hidden_user] != 0
      row.delete(:is_system_user); row.delete(:is_hidden_user); row.delete(:id)
    else
      row[:title] = row[:user_title]; row.delete(:user_title)  # as user_title, because title displays as "User Group Report" in HTML report
    end

    row[:groups] = UserGroupsSubreport.new( self, user_id ).get_content

    puts row
  end


  def identifier_field
    :name
  end

  def page_break
    false
  end


  # these two go together because the base class and templates assume all reports are repository based.
  def repository
    "Global repository"
  end

  def after_tasks
    info.delete(:repository)
  end

end

class UserGroupsSubreport < AbstractSubreport

  register_subreport('groups', [ 'user' ])

  def initialize( parent_report, user_id )
    super(parent_report)
    @user_id = user_id
  end

  def query_string
    "select description from `group`
    where id in (select group_id from group_user where user_id = #{db.literal(@user_id)} )"
  end

  def self.field_name
    'groups'
  end
end