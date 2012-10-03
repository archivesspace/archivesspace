class ImportFile #< ActiveRecord::Base
  
  attr_accessor :upload
  attr_accessor :path

  def initialize(upload)
    name = upload['import_file'].original_filename
    directory = Rails.root.join('tmp', 'import')
    
    path = File.join(directory, name)
    File.open(path, "wb") { |f| f.write(upload['import_file'].read) }  

    self.path = path

    self

  end
  

end
