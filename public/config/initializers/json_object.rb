require "jsonmodel"
require "memoryleak"

if not ENV['DISABLE_STARTUP']
  JSONModel::init(:client_mode => true,
                :priority => :high,
                :url => AppConfig[:backend_url])


  MemoryLeak::Resources.define(:repository, proc { JSONModel(:repository).all }, 60)

  JSONModel::Notification::add_notification_handler("REPOSITORY_CHANGED") do |msg, params|
    MemoryLeak::Resources.refresh(:repository)
  end

  JSONModel::Notification.start_background_thread

  JSONModel::add_error_handler do |error|
    if error["code"] == "SESSION_GONE"
      raise ArchivesSpacePublic::SessionGone.new("Your backend session was not found")
    end
    if error["code"] == "SESSION_EXPIRED"
      raise ArchivesSpacePublic::SessionExpired.new("Your session expired due to inactivity. Please sign in again.")
    end
  end

end


include JSONModel
