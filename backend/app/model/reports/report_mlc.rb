# MLC join helper shared by reports and subreports.
#
# Migration 177 moves `title` and other multilingual fields from the base
# record type tables and into per-language `*_mlc` tables. Any query that
# wants one of those fields needs to join to the record's own `_mlc` row.
#
# ANW-2907: As initial MVP have reports always use the AppConfig default
# language/script. Per-run language selection is out of scope for now.
module ReportMlc

  def mlc_lang_condition(table_name)
    lang = RequestContext.default_description_language
    "#{table_name}_mlc.language_id = #{db.literal(lang[:language_id])}" \
      " and #{table_name}_mlc.script_id = #{db.literal(lang[:script_id])}"
  end

  def mlc_join(table_name, id_column = "#{table_name}.id")
    "left join #{table_name}_mlc on #{table_name}_mlc.#{table_name}_id = #{id_column}" \
      " and #{mlc_lang_condition(table_name)}"
  end
end
