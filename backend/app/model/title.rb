class Title < Sequel::Model(:title)
  include ASModel
  corresponds_to JSONModel(:title)

  set_model_scope :global

  def validate
    super
    validates_presence [:title]
  end

  def to_hash
    {
      "title" => self.title,
      "type" => self.type,
      "language" => self.language,
      "script" => self.script,
    }
  end

  def hash
    [title, type, language, script].hash
  end

  # Ignore foreign keys, modification timestamps, etc when testing for equality. Otherwise, you end up
  # in a situation when comparing "duplicated" records where titles that should be considered equal end up not being so:
  # -:title => [#<Title @values={:id=>4, :resource_id=>nil, :archival_object_id=>1, :digital_object_id=>nil, :digital_object_component_id=>nil, :title=>"Archival Object Parent 1 1745968650", :type_id=>nil, :language_id=>nil, :script_id=>nil, :created_by=>"admin", :last_modified_by=>"admin", :create_time=>2025-04-29 23:17:37 UTC, :system_mtime=>2025-04-29 23:17:37 UTC, :user_mtime=>2025-04-29 23:17:37 UTC}>],
  # +:title => [#<Title @values={:id=>12, :resource_id=>nil, :archival_object_id=>8, :digital_object_id=>nil, :digital_object_component_id=>nil, :title=>"Archival Object Parent 1 1745968650", :type_id=>nil, :language_id=>nil, :script_id=>nil, :created_by=>"admin", :last_modified_by=>"admin", :create_time=>2025-04-29 23:17:39 UTC, :system_mtime=>2025-04-29 23:17:39 UTC, :user_mtime=>2025-04-29 23:17:39 UTC}>]
  def ==(other)
    other.class == self.class &&
      other.title == self.title &&
      other.type == self.type &&
      other.language == self.language &&
      other.script == self.script
  end

  alias :eql? :==
end
