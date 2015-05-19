Sequel.extension :inflector
Sequel.extension :pagination


module MigrationUtils
  def self.shorten_table(name)
    name.to_s.split("_").map {|s| s[0...3]}.join("_")
  end
end


module EachByPage

  def each_by_page(page_size = 1000)
    self.extension(:pagination).each_page(page_size) do |page_ds|
      page_ds.each do |row|
        yield(row)
      end
    end
  end

end


module Sequel
  class Dataset
    include EachByPage
  end
end


def blobify(db, s)
  (db.database_type == :derby) ? s.to_sequel_blob : s
end


def create_editable_enum(name, values, default = nil, opts = {})
  create_enum(name, values, default, true, opts)
end


def create_enum(name, values, default = nil, editable = false, opts = {})
  id = self[:enumeration].insert(:name => name,
                                 :json_schema_version => 1,
                                 :editable => editable ? 1 : 0,
                                 :create_time => Time.now,
                                 :system_mtime => Time.now,
                                 :user_mtime => Time.now)

  id_of_default = nil

  readonly_values = Array(opts[:readonly_values])
  # we updated the schema to include ordering for enum values. so, we will need
  # those for future adding enums
  include_position = self.schema(:enumeration_value).flatten.include?(:position)
  
  values.each_with_index do |value, i|
    props = { :enumeration_id => id, :value => value, :readonly => readonly_values.include?(value) ? 1 : 0 } 
    props[:position] = i if include_position

    id_of_value =  self[:enumeration_value].insert(props)
                                       
    id_of_default = id_of_value if value === default
  end

  if !id_of_default.nil?
    self[:enumeration].where(:id => id).update(:default_value => id_of_default)
  end
end
