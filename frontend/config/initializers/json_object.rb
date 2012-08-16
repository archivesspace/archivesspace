require "jsonmodel"

JSONModel::init(:client_mode => true,
                :url => ArchivesSpace::Application.config.backend_url)

JSONModel::add_error_handler do |error|
  if error["code"] == "SESSION_GONE"
    raise ArchivesSpace::SessionGone.new("Your backend session was not found")
  end
end

include JSONModel

