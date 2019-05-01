require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Cleaning slugs for repositories")

    self[:repository].all.each do |r|
      # This code is duplicated from SlugHelpers#clean_slug
      slug = r[:repo_code].downcase
                          .gsub(" ", "_")
                          .gsub("--", "")
                          .gsub("'", "")
                          .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!.]/, "")
                          .gsub(/_[_]+/, "_")
                          .gsub(/^_/, "")
                          .gsub(/_$/, "")
                          .slice(0, 50)

      if slug.match(/^(\d)+$/)
        slug = slug.prepend("__")
      end
      self[:repository].where(:id => r[:id]).update(:slug => slug)
    end

    # Repo slugs should default to auto generation
    alter_table(:repository) do
      set_column_default :is_slug_auto, 1
    end

  end
end
