class OAIConfig < Sequel::Model(:oai_config)
  include ASModel

  # validations
  # only one row in table allowed
  # oai_repository_name must have a value
  # oai_admin_email must have a value
  # oai_record_prefix must have a value

  def validate
  	validate_single_record

  	validates_presence :oai_record_prefix
  	validates_presence :oai_admin_email
  	validates_presence :oai_repository_name

  	# TODO: check for valid email in oai_admin_email
  end

  def validate_single_record
  	unless self.select.count == 0
      errors.add(:base, 'Cannot have more than one record in oai_config table.') 
  	end
  end

end