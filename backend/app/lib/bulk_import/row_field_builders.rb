# Builds JSONModel fragments (dates, notes, file versions) from spreadsheet row
# cells. Shared by the Archival Object and Digital Object bulk importers.
module RowFieldBuilders
  # The following methods assume @report is defined, and is a BulkImportReport object
  def create_date(dates_label, date_begin, date_end, date_type, expression, date_certainty, date_era = nil, date_calendar = nil)
    date_str = "(Date: type:#{date_type}, label: #{dates_label}, begin: #{date_begin}, end: #{date_end}, expression: #{expression})"
    date = {}

    begin
      date['date_type'] = @date_types.value(date_type || "inclusive")
    rescue Exception => e
      @report.add_errors(I18n.t("bulk_import.error.date_type",
                                :what => date_type,
                                :date_str => date_str))

      return nil
    end
    begin
      date['label'] = @date_labels.value(dates_label || "creation")
    rescue Exception => e
      @report.add_errors(I18n.t("bulk_import.error.date_label",
                                :what => dates_label,
                                :date_str => date_str))

      return nil
    end

    apply_cv_field(date, "certainty", @date_certainty, date_certainty, date_str)
    apply_cv_field(date, "era", @date_era, date_era, date_str)
    apply_cv_field(date, "calendar", @date_calendar, date_calendar, date_str)

    date["begin"] = date_begin if date_begin
    date["end"] = date_end if date_end
    date["expression"] = expression if expression
    invalids = JSONModel::Validations.check_date(date)
    unless (invalids.nil? || invalids.empty?)
      err_msg = ""
      invalids.each do |inv|
        err_msg << " #{inv[0]}: #{inv[1]}"
      end
      @report.add_errors(I18n.t("bulk_import.error.invalid_date", :what => err_msg, :date_str => date_str))
      return nil
    end
    if date_type == "single" && !date_end.nil?
      @report.add_errors(I18n.t("bulk_import.warn.single_date_end", :date_str => date_str))
    end
    d = JSONModel(:date).new(date)
  end

  def handle_notes(ao, hash, dig_obj = false)
    @nh = NotesHandler.new
    errs = []
    hash.keys.grep(/^n_/).each do |key|
      next if hash[key].nil?
      content = hash[key]
      type = key.match(/n_(.+)$/)[1]
      extras = handle_note_restriction_params(type, hash)
      pubnote = resolve_publish(hash, "p_#{type}", ao.publish)
      note_label = hash["l_#{type}"]
      begin
        note = @nh.create_note(type, note_label, content, pubnote, dig_obj,
                                extras[:b_date], extras[:e_date], extras[:local_restrictions])
        ao.notes.push(note) if note
      rescue BulkImportException => bei
        errs.push([bei.message])
      end
    end
    errs
  end

  def handle_note_restriction_params(type, hash)
    case type
    when 'accessrestrict'
      accessrestrict_note_params(hash)
    when 'userestrict'
      { b_date: hash['b_userestrict'], e_date: hash['e_userestrict'] }
    else
      {}
    end
  end

  def accessrestrict_note_params(hash)
    restrictions = hash.keys.grep(/^t_accessrestrict(_\d+)?$/).sort_by { |k| k[/\d+/].to_i }.filter_map { |k| hash[k] unless hash[k].to_s.strip.empty? }
    {
      b_date: hash['b_accessrestrict'],
      e_date: hash['e_accessrestrict'],
      local_restrictions: restrictions.empty? ? nil : restrictions,
    }
  end

  def resolve_publish(hash, column, default_publish)
    normalize_boolean_column(hash, column)
    hash[column].nil? ? default_publish : hash[column]
  end

  def representative_file_version
    if @row_hash['rep_file_uri'].present?
      {
        is_representative: true,
        file_uri: @row_hash['rep_file_uri'],
        xlink_actuate_attribute: @row_hash['rep_xlink_actuate_attribute'],
        xlink_show_attribute: @row_hash['rep_xlink_show_attribute'],
        publish: true,
        use_statement: @row_hash['rep_use_statement'],
        file_format_name: @row_hash['rep_file_format'],
        file_format_version: @row_hash['rep_file_format_version'],
        file_size_bytes: @row_hash['rep_file_size'].to_i,
        checksum: @row_hash['rep_checksum'],
        checksum_method: @row_hash['rep_checksum_method'],
        caption: @row_hash['rep_caption']
      }
    end
  end

  def non_representative_file_version
    if @row_hash['nonrep_file_uri'].present?
      {
        is_representative: false,
        file_uri: @row_hash['nonrep_file_uri'],
        xlink_actuate_attribute: @row_hash['nonrep_xlink_actuate_attribute'],
        xlink_show_attribute: @row_hash['nonrep_xlink_show_attribute'],
        publish: @row_hash['nonrep_publish'],
        use_statement: @row_hash['nonrep_use_statement'],
        file_format_name: @row_hash['nonrep_file_format'],
        file_format_version: @row_hash['nonrep_file_format_version'],
        file_size_bytes: @row_hash['nonrep_file_size'].to_i,
        checksum: @row_hash['nonrep_checksum'],
        checksum_method: @row_hash['nonrep_checksum_method'],
        caption: @row_hash['nonrep_caption']
      }
    end
  end

  def normalize_boolean_column(row_hash, column)
    return if row_hash[column].nil?
    return if [TrueClass, FalseClass].include? row_hash[column].class
    row_hash[column] = ['t', '1', 'true'].include? row_hash[column].to_s.strip.downcase
  end

  private

  def apply_cv_field(date, field_name, cv_list, value, date_str)
    return unless value
    begin
      date[field_name] = cv_list.value(value)
    rescue Exception => e
      @report.add_errors(I18n.t("bulk_import.error.#{field_name}", :what => e.message, :date_str => date_str))
    end
  end
end
