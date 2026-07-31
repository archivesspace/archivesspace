# Spec-only helper for finding MLC-using records by title across every
# language variant.  Walks the model's +_mlc+ table instead of the main
# table because title now lives on the _mlc rows.
def find_by_mlc_title(model, title)
  model.where(:id => model.db[model.mlc_table].where(:title => title).select(:"#{model.table_name}_id"))
end
