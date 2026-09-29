Sequel.extension :inflector
Sequel.extension :pagination


module MigrationUtils
  def self.shorten_table(name)
    name.to_s.split("_").map {|s| s[0...3]}.join("_")
  end

  module RDETemplateFix
    ::RDETemplateFix = MigrationUtils::RDETemplateFix
    CONFIG = {
      deprecated: 'colLang',
      replacements: {
        'colLanguage' => 'eng',
        'colScript' => 'Latn',
      },
      field_updates: {
        order: :update_array,
        visible: :update_array,
        defaults: :update_hash
      }
    }
    def self.update_array(obj)
      did_something = false
      deprecated_idx = obj.index(CONFIG[:deprecated])
      if deprecated_idx
        obj.insert(deprecated_idx, *CONFIG[:replacements].keys)
        obj.delete(CONFIG[:deprecated])
        did_something = true
      end
      did_something
    end

    def self.update_hash(obj)
      did_something = false
      if obj.key? CONFIG[:deprecated]
        obj.merge!(CONFIG[:replacements])
        obj.delete((CONFIG[:deprecated]))
        did_something = true
      end
      did_something
    end
  end

  # Chooses the display thumbnail and display link of one digital object or digital object
  # component from what the earlier display rules showed (migration 180), so that existing
  # images and links keep showing:
  #
  #   Display thumbnail: the first published file version that is, in order of preference,
  #     1. marked is_representative
  #     2. use statement image-thumbnail
  #     3. an http(s) file URI with xlink show attribute embed that is not a IIIF manifest
  #     4. file format jpeg or gif
  #
  #   Display link: the file version following the display thumbnail, if published; with no
  #     display thumbnail, the last published http(s) or data: file version that is not embedded
  #     and not a IIIF manifest.
  module FileVersionDisplayFlags
    ::FileVersionDisplayFlags = MigrationUtils::FileVersionDisplayFlags

    # file_versions: the file_version rows of one record, in id order
    # enum_ids: the enumeration value ids of :image_thumbnail and :text_json (use statement),
    #   :embed (xlink show attribute), :iiif and :images (file format names, an array)
    # Returns [thumbnail, link]: the rows to flag, each possibly nil
    def self.choose(file_versions, enum_ids)
      published = file_versions.select { |fv| fv[:publish] == 1 }

      thumbnail = thumbnail_tiers(enum_ids).lazy.map { |tier| published.find(&tier) }.find(&:itself)

      link =
        if thumbnail
          following = file_versions[file_versions.index(thumbnail) + 1]
          following if following && following[:publish] == 1
        else
          published.select { |fv| legacy_link?(fv, enum_ids) }.last
        end

      [thumbnail, link]
    end

    def self.thumbnail_tiers(enum_ids)
      [
        ->(fv) { fv[:is_representative] == 1 },
        ->(fv) { fv[:use_statement_id] == enum_ids[:image_thumbnail] },
        ->(fv) {
          file_uri(fv).start_with?('http') && fv[:xlink_show_attribute_id] == enum_ids[:embed] && !iiif_manifest?(fv, enum_ids)
        },
        ->(fv) { enum_ids[:images].include?(fv[:file_format_name_id]) },
      ]
    end

    def self.legacy_link?(fv, enum_ids)
      (file_uri(fv).start_with?('http') || file_uri(fv).start_with?('data:')) &&
        fv[:xlink_show_attribute_id] != enum_ids[:embed] && !iiif_manifest?(fv, enum_ids)
    end

    def self.iiif_manifest?(fv, enum_ids)
      fv[:file_format_name_id] == enum_ids[:iiif] &&
        fv[:use_statement_id] == enum_ids[:text_json] &&
        fv[:xlink_show_attribute_id] == enum_ids[:embed]
    end

    def self.file_uri(fv)
      fv[:file_uri].to_s.strip
    end
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


def create_editable_enum(name, values, default = nil, opts = {})
  create_enum(name, values, default, true, opts)
end

def get_enum_value_id(enum_name, enum_value)
  enum_id = self[:enumeration].filter(:name => enum_name).select(:id).first[:id]

  if enum_id
    enum_value_id = self[:enumeration_value].filter(:value => enum_value,
                                                    :enumeration_id => enum_id)
                                            .select(:id)
                                            .first[:id]

    enum_value_id = -1 unless enum_value_id
    return enum_value_id
  else
    return -1
  end
end


def get_enum_id(enum_name)
  enum_id = self[:enumeration].filter(:name => enum_name).select(:id).first[:id]

  if enum_id
    return enum_id
  else
    return -1
  end
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

    id_of_value = self[:enumeration_value].insert(props)

    id_of_default = id_of_value if value === default
  end

  if !id_of_default.nil?
    self[:enumeration].where(:id => id).update(:default_value => id_of_default)
  end
end

# adds a value to an existing enumeration.
# if applicable, the new value is set to last position.
def add_values_to_enum(name, values)
  enum_id = get_enum_id(name)
  include_position = self.schema(:enumeration_value).flatten.include?(:position)

  if enum_id != -1
    # find the last position
    if include_position
      last_position = self[:enumeration_value].where(:enumeration_id => enum_id)
                                              .order(:position)
                                              .last[:position]

      # if no other values are present, last pos is zero
      last_position = 0 if last_position.nil?
    end

    values.each_with_index do |value, ind|
      next if self[:enumeration_value].where(enumeration_id: enum_id, value: value).any?

      props = { :enumeration_id => enum_id,
                :value => value,
                :readonly => 0 }

      i = ind += 1 # index starts at zero
      props[:position] = i + last_position if include_position

      self[:enumeration_value].insert(props)
    end
  else
    raise "enumeration not found."
  end
end

# used in migration 126 for creating structured dates
def fits_structured_date_format?(expr)
  matches_y           = (expr =~ /^[\d]{1}$/) == 0
  matches_y_mm        = (expr =~ /^[\d]{1}-[\d]{2}$/) == 0
  matches_yy          = (expr =~ /^[\d]{2}$/) == 0
  matches_yy_mm       = (expr =~ /^[\d]{2}-[\d]{2}$/) == 0
  matches_yyy         = (expr =~ /^[\d]{3}$/) == 0
  matches_yyy_mm      = (expr =~ /^[\d]{3}-[\d]{2}$/) == 0
  matches_yyyy        = (expr =~ /^[\d]{4}$/) == 0
  matches_yyyy_mm     = (expr =~ /^[\d]{4}-[\d]{2}$/) == 0
  matches_yyyy_mm_dd  = (expr =~ /^[\d]{4}-[\d]{2}-[\d]{2}$/) == 0
  matches_mm_yyyy     = (expr =~ /^[\d]{2}-[\d]{4}$/) == 0
  matches_mm_dd_yyyy = (expr =~ /^[\d]{4}-[\d]{2}-[\d]{2}$/) == 0

  return matches_yyyy || matches_yyyy_mm || matches_yyyy_mm_dd || matches_yyy || matches_yy || matches_y || matches_yyy_mm || matches_yy_mm || matches_y_mm || matches_mm_yyyy || matches_mm_dd_yyyy
end

# used in migration 126 for creating structured dates
# put any date expression into a structured_date_single with role: begin
def create_structured_date_for_expr(r, rel)
  role_id_begin = get_enum_value_id("date_role", "begin")
  type_id_single = get_enum_value_id("date_type_structured", "single")

  l = self[:structured_date_label].insert(:date_label_id => r[:label_id],
                                          :date_type_structured_id => type_id_single,
                                          :date_certainty_id => r[:certainty_id],
                                          :date_era_id => r[:era_id],
                                          :date_calendar_id => r[:calendar_id],
                                          :create_time => Time.now,
                                          :system_mtime => Time.now,
                                          :user_mtime => Time.now,
                                          rel => r[rel])

  self[:structured_date_single].insert(:date_role_id => role_id_begin,
                                :date_expression => r[:expression],
                                :structured_date_label_id => l,
                                :create_time => Time.now,
                                :system_mtime => Time.now,
                                :user_mtime => Time.now)
end

# used in migration 126 for creating structured dates
def log_date_migration(r)
  $stderr.puts("Migrating date record to structured_date format")
  $stderr.puts("================================")
  $stderr.puts("id                       : " + r[:id].to_s)
  $stderr.puts("agent_person_id          : " + r[:agent_person_id].to_s)
  $stderr.puts("agent_family_id          : " + r[:agent_family_id].to_s)
  $stderr.puts("agent_corporate_entity_id: " + r[:agent_corporate_entity_id].to_s)
  $stderr.puts("agent_software_id        : " + r[:agent_software_id].to_s)
  $stderr.puts("name_person_id           : " + r[:name_person_id].to_s)
  $stderr.puts("name_family_id           : " + r[:name_family_id].to_s)
  $stderr.puts("name_corporate_entity_id : " + r[:name_corporate_entity_id].to_s)
  $stderr.puts("name_software_id         : " + r[:name_software_id].to_s)
  $stderr.puts("related_agents_rlshp_id  : " + r[:name_software_id].to_s)
  $stderr.puts("date_type_id             : " + r[:agent_software_id].to_s)
  $stderr.puts("label_id                 : " + r[:label_id].to_s)
  $stderr.puts("certainty_id             : " + r[:certainty_id].to_s)
  $stderr.puts("expression               : " + r[:expression].to_s)
  $stderr.puts("begin                    : " + r[:begin].to_s)
  $stderr.puts("end                      : " + r[:end].to_s)
  $stderr.puts("era_id                   : " + r[:era_id].to_s)
  $stderr.puts("calendar_id              : " + r[:calendar_id].to_s)
  $stderr.puts("\n")
end
