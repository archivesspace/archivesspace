class Accession < Sequel::Model(:accessions)
  plugin :validation_helpers
  include ASModel

  def validate
    super
    validates_unique([:id_0, :id_1, :id_2, :id_3], :only_if_modified => true)
    validates_presence(:id_0, :message => "You must provide an accession ID")
  end
end
