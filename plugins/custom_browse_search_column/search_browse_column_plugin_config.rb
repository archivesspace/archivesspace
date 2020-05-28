module SearchAndBrowseColumnPlugin
  def self.config
    {
      'resource' => {
        :add => {
          'some_custom_field' => {:field => 'some_custom_field'}
        },
        :remove => []
      }
    }
  end
end
