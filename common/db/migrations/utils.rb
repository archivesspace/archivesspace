Sequel.extension :inflector

module MigrationUtils
  def self.shorten_table(name)
    name.to_s.split("_").map {|s| s[0...3]}.join("_")
  end
end
