class Accession < Sequel::Model(:accessions)
  plugin :validation_helpers
  include ASModel

  def validate
    super
    validates_unique([:accession_id_0, :accession_id_1, :accession_id_2, :accession_id_3],
                     :only_if_modified => true)
  end
end
