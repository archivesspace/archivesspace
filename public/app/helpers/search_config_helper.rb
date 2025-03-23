module SearchConfigHelper
  def self.default_search_scope
    scope = AppConfig[:search_default_scope]

    # Validate the scope and default to all_record_types if invalid
    valid_scopes = ['all_record_types', 'collections_only']
    unless valid_scopes.include?(scope)
      Rails.logger.warn("Invalid search_default_scope setting: '#{scope}'. Using 'all_record_types' instead.")
      scope = 'all_record_types'
    end

    scope
  end

  def self.default_search_all_records?
    default_search_scope == 'all_record_types'
  end
end
