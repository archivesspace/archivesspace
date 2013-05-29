require 'atomic'

class EditMediator

  # The table of all editing clients
  @active_edits = Atomic.new({})

  Editor = Struct.new(:editing_user, :uri, :lock_version, :last_report_time)


  def self.record(user, uri, lock_version, last_report_time)
    @active_edits.update {|edits|
      edits.merge({[user, uri] => Editor.new(user, uri, lock_version, last_report_time)})
    }
  end

end
