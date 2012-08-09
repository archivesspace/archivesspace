module JSONModel::Validations
  extend JSONModel


  def self.check_identifier(hash, exceptions)
    ids = (0...4).map {|i| hash["id_#{i}"]}

    if ids.reverse.drop_while {|elt| elt.nil?}.include?(nil)
      exceptions[:errors][:identifier] ||= []
      exceptions[:errors][:identifier] << "must not contain blank entries"
    end
  end


  [:archival_object, :accession].each do |type|
    JSONModel(type).add_validation do |hash, exceptions|
      check_identifier(hash, exceptions)
    end
  end

end
