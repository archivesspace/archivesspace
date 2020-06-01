module SearchAndBrowseColumnPlugin
  def self.config
    {
      'resource' => {
        # you can add columns that are not options by default by adding an entry for them in this hash
        # minimally it should have colmun name => {:field => column name} but you can also add additonal options like sortable
        :add => {
          'some_custom_field' => {:field => 'some_custom_field'}
        },
        # you can remove columns that are options by default by adding their name to this list
        :remove => ['audit_info']
      }
    }
  end
end
