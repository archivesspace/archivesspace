require "jsonmodel"

JSONModel::init(:client_mode => true,
                :priority => :high,
                :url => AppConfig[:backend_url],
                :allow_other_unmapped => AppConfig[:allow_other_unmapped])


if not ENV['DISABLE_STARTUP']

  JSONModel::Webhooks::add_notification_handler("REPOSITORY_CHANGED") do |msg, params|
    MemoryLeak::Resources.refresh(:repository)
  end

  JSONModel::Webhooks::add_notification_handler("BACKEND_STARTED") do |msg, params|
    MemoryLeak::Resources.invalidate_all!
  end

end


include JSONModel
