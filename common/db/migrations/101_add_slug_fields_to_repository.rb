require_relative 'utils'

Sequel.migration do


# Do I want to create a slug table?
# makes it possible to enforce uniqueness
# not sure about updating something in another table. Had a hard time with that with the ARKs table. 

# SLugs table?
# slugs
# 
# id
# sluggable_type_id #=> enum_value
# sluggable_id      #=> entity id value
# slug
# autogenerate_enabled
# -- required fields

  up do
  	alter_table(:repository) do
  		String :slug
  	end
  end

  down do
  	alter_table(:repository) do
  		drop_column(:slug)
  		drop_column(:is_slug_locked)
  	end
  end

end