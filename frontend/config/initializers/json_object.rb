require "jsonmodel"
require "asutils"
require "memoryleak"
require "client_enum_source"
require "jsonmodel_i18n_mixin"

module RailsFormMixin

  def self.included(base)
    # For any array types in this schema, define a setter that will trigger
    # form_helper to do what we want.
    base.schema['properties'].each do |name, property|
      if property['type'].is_a?(String) && property['type'].downcase == 'array'
        base.instance_eval do
          define_method "#{name}_attributes=" do
          end
        end
      end
    end
  end


  def persisted?
    false
  end
end


JSONModel::init(:client_mode => true,
                :priority => :high,
                :mixins => [RailsFormMixin, 
                            JSONModelI18nMixin],
                :url => AppConfig[:backend_url],
                :enum_source => ClientEnumSource.new,
                :allow_other_unmapped => AppConfig[:allow_other_unmapped],
                :i18n_source => I18n)


if not ENV['DISABLE_STARTUP']
  JSONModel::add_error_handler do |error|
    if error["code"] == "SESSION_GONE"
      raise ArchivesSpace::SessionGone.new(I18n.t("session.gone"))
    end
    if error["code"] == "SESSION_EXPIRED"
      raise ArchivesSpace::SessionExpired.new(I18n.t("session.expired"))
    end
  end


  MemoryLeak::Resources.define(:repository, proc { JSONModel(:repository).all }, 60)
  MemoryLeak::Resources.define(:vocabulary, proc { JSONModel(:vocabulary).all }, 60)
  MemoryLeak::Resources.define(:acl_system_mtime, proc { Time.now.to_i }, 60,
                               :init => 0)
  MemoryLeak::Resources.define(:preferences_system_mtime, proc { Time.now.to_i }, nil,
                               :init => 0)
  MemoryLeak::Resources.define(:job_types, proc {
    JSONModel::HTTP.get_json('/job_types').sort {|x,y| I18n.t("job.types.#{x}") <=> I18n.t("job.types.#{y}") }
                               }, 60)


  JSONModel::Notification::add_notification_handler("REPOSITORY_CHANGED") do |msg, params|
    MemoryLeak::Resources.refresh(:repository)
  end


  JSONModel::Notification::add_notification_handler("VOCABULARY_CHANGED") do |msg, params|
    MemoryLeak::Resources.refresh(:vocabulary)
  end

  JSONModel::Notification::add_notification_handler("BACKEND_STARTED") do |msg, params|
    MemoryLeak::Resources.invalidate_all!
  end

  JSONModel::Notification::add_notification_handler("REFRESH_ACLS") do |msg, params|
    MemoryLeak::Resources.refresh(:acl_system_mtime)
  end

  JSONModel::Notification::add_notification_handler("REFRESH_PREFERENCES") do |msg, params|
    MemoryLeak::Resources.refresh(:preferences_system_mtime)
  end

  JSONModel::Notification::add_notification_handler("ENUMERATION_CHANGED") do |msg, params|
    MemoryLeak::Resources.refresh(:enumerations)
  end


  JSONModel::Notification.start_background_thread
end


include JSONModel
