# coding: utf-8
require_relative 'utils'
require 'date'

POSSIBLE_DATE_RANGE_A = /^\d{2}(\d{2})\s?-\s?(\d{2})\s*$/
POSSIBLE_DATE_RANGE_B = /^(\d{3}[\d\?-]{1,2})\s?-\s?(\d{3}[\d\?-]{1,2})\s*$/
NUMBERS_AND_SLASHES = /^\s*[\d\\]+\s*$/
PROBABLE_DATE = /^\s*\d{4}([-\s]\d{2})?([-\s][0123]?\d{1})?\s*$/
CONTAINS_PROBABLE_DATE = /\d{4}(-\d{2})?(-\d{2})?/
PROBABLE_DATE_INLINE = /\d{4}/

def process_date_expression(dx)
  if dx.match?(/undated/i) || dx.match?(/bulk/i)
    return [dx, nil]
  end
  dx_orig = dx.dup
  _dx = dx.dup

  Date::MONTHNAMES.each_with_index do |name, i|
    next if name.nil?
    _dx.sub!(name, i.to_s.rjust(2, "0"))
  end

  Date::ABBR_MONTHNAMES.each_with_index do |name, i|
    next if name.nil?
    _dx.sub!("#{name}.", i.to_s.rjust(2, "0"))
    _dx.sub!(name, i.to_s.rjust(2, "0"))
  end

  dx.sub!('–', '-') if dx.split('–').size == 2
  dx.sub!('—', '-') if dx.split('—').size == 2

  if dx.match(POSSIBLE_DATE_RANGE_A) && ($1.to_i < $2.to_i)
    return [dx[0..3], (dx[0..1] + dx[-2..-1])]
  end

  if dx.match(POSSIBLE_DATE_RANGE_B)
    return [$1, $2]
  end

  if dx.split('-').size > 2 && (dx.split('-').size.modulo(2) == 0)
    a = dx.split('-')
    index = a.size / 2
    if a[0...index].join('-').match?(PROBABLE_DATE) && a[index..-1].join('-').match?(PROBABLE_DATE)
      return [a[0...index].join('-'), a[index..-1].join('-')]
    end
  end

  if _dx.split('-').size == 2 && _dx.split('-').select { |x| x.match?(PROBABLE_DATE) }.size == 2
    return dx.split('-')
  end

  if _dx.split('/').size == 2 && _dx.split('/').select { |x| x.match?(PROBABLE_DATE) }.size == 2
    return dx.split('/')
  end

  # assume anything following a comma after a date is an end date
  if dx.split(',').size == 2 && dx.split(',')[0].match?(PROBABLE_DATE) && dx.split(',')[1].match?(CONTAINS_PROBABLE_DATE) && dx.index('-').nil?
    return dx.split(',')
  end

  #assume a single dash is a range separator if between phrases each ending with a date
  if dx.split('-').size == 2
    if dx.index(',').nil? && dx.split('-').select { |x| x.match?(/\d{4}\s*$/) }.size == 2 #.size == 2 && dx.index(',').nil?
      return dx.split('-')
    elsif dx.split('-') && (dx.split('-').select { |x|
                              x.match?(/^\s?([[:alpha:]]+)(\s[0123]?\d,?)?\s\d{4}\s?$/) && (Date::MONTHNAMES.include?($1))
                            }.size == 2)

      return dx.split('-')
    elsif dx.split('-') && (dx.split('-').select { |x|
                              x.match?(/^\s?([[:alpha:]]+)\.?(\s[0123]?\d,?)?\s\d{4}\s?$/) && (Date::ABBR_MONTHNAMES.include?($1))
                            }.size == 2)

      return dx.split('-')
    end
  end

  return [dx_orig, nil]
end

def create_structured_date(r, rel)
  type_id = (r[:date_type_id] == DATE_TYPE_SINGLE_ID_ORIG ? TYPE_ID_SINGLE : TYPE_ID_RANGE)

  l = self[:structured_date_label].insert(:date_label_id => r[:label_id],
                                          :date_type_structured_id => type_id,
                                          :date_certainty_id => r[:certainty_id],
                                          :date_era_id => r[:era_id],
                                          :date_calendar_id => r[:calendar_id],
                                          :create_time => Time.now,
                                          :system_mtime => Time.now,
                                          :user_mtime => Time.now,
                                          rel => r[rel])

  if type_id == TYPE_ID_RANGE
    dates = begin
      process_date_expression(r[:expression])
    rescue
      [r[:expression], nil]
    end

    self[:structured_date_range].insert(:begin_date_standardized => r[:begin],
                                        :end_date_standardized => r[:end],
                                        :begin_date_expression => dates[0],
                                        :end_date_expression => dates[1],
                                        :structured_date_label_id => l,
                                        :create_time => Time.now,
                                        :system_mtime => Time.now,
                                        :user_mtime => Time.now)

  else
    self[:structured_date_single].insert(:date_role_id => r[:expression]&.match?(/^\s?-\s?\d{4}$/) ? ROLE_ID_END : ROLE_ID_BEGIN,
                                         :date_standardized => r[:begin],
                                         :date_expression => r[:expression],
                                         :structured_date_label_id => l,
                                         :create_time => Time.now,
                                         :system_mtime => Time.now,
                                         :user_mtime => Time.now)
  end
end

Sequel.migration do
  up do
    $stderr.puts("Migrating agent dates from 'date' to 'structured_date' table")

    DATE_TYPE_SINGLE_ID_ORIG = get_enum_value_id("date_type", "single")
    DATE_TYPE_RANGE_ID_ORIG = get_enum_value_id("date_type", "range")
    DATE_TYPE_BULK_ID_ORIG = get_enum_value_id("date_type", "bulk")
    DATE_TYPE_INCLUSIVE_ID_ORIG = get_enum_value_id("date_type", "inclusive")

    ROLE_ID_BEGIN = get_enum_value_id("date_role", "begin")
    ROLE_ID_END = get_enum_value_id("date_role", "end")
    TYPE_ID_SINGLE = get_enum_value_id("date_type_structured", "single")
    TYPE_ID_RANGE = get_enum_value_id("date_type_structured", "range")

    # figure out which FK is defined, so we can create the right relationship later
    self[:date].order(:id).paged_each do |r|
      if r[:agent_person_id]
        rel = :agent_person_id
      elsif r[:agent_family_id]
        rel = :agent_family_id
      elsif r[:agent_corporate_entity_id]
        rel = :agent_corporate_entity_id
      elsif r[:agent_software_id]
        rel = :agent_software_id
      elsif r[:name_person_id]
        rel = :name_person_id
      elsif r[:name_family_id]
        rel = :name_family_id
      elsif r[:name_corporate_entity_id]
        rel = :name_corporate_entity_id
      elsif r[:name_software_id]
        rel = :name_software_id
      elsif r[:related_agents_rlshp_id]
        rel = :related_agents_rlshp_id
      else
        next
      end

      log_date_migration(r)
      create_structured_date(r, rel)

      self[:date].filter(:id => r[:id]).delete
    end # of loop

    # remove agents related FKs from date table
    alter_table(:date) do
      drop_foreign_key(:agent_person_id)
      drop_foreign_key(:agent_family_id)
      drop_foreign_key(:agent_corporate_entity_id)
      drop_foreign_key(:agent_software_id)
      drop_foreign_key(:name_person_id)
      drop_foreign_key(:name_family_id)
      drop_foreign_key(:name_corporate_entity_id)
      drop_foreign_key(:name_software_id)
      drop_foreign_key(:related_agents_rlshp_id)
    end
  end # of up
end # of migration
