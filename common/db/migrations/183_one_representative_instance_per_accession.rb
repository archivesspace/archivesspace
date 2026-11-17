require 'json'

# Gives accessions the constraint that migration 067 gave resources and archival objects: only one
# representative instance. Where the API saved several, the first one stays representative.
Sequel.migration do
  up do
    accessions = self[:accession]
                   .filter(:id => self[:instance]
                                    .exclude(:accession_id => nil)
                                    .filter(:is_representative => 1)
                                    .group(:accession_id)
                                    .having { count.function.* > 1 }
                                    .select(:accession_id))
                   .order(:repo_id, :id)
                   .select(:id, :repo_id, :identifier)
                   .all

    unless accessions.empty?
      $stderr.puts("Accessions with more than one representative instance (the first one stays representative):")
      accessions.each do |accession|
        identifier = JSON.parse(accession[:identifier]).compact.join('-')
        $stderr.puts("  /repositories/#{accession[:repo_id]}/accessions/#{accession[:id]} #{identifier}")
      end
    end

    accessions.map { |accession| accession[:id] }.each_slice(1000) do |ids|
      representatives = self[:instance].filter(:accession_id => ids, :is_representative => 1)
      first_ids = representatives.group(:accession_id).select { min(:id).as(:id) }.map(:id)

      representatives.exclude(:id => first_ids).update(:is_representative => nil)
      self[:accession].filter(:id => ids).update(:system_mtime => Time.now)
    end

    alter_table(:instance) do
      add_unique_constraint([:is_representative, :accession_id], :name => 'accession_one_representative_instance')
    end
  end

  down do
  end
end
