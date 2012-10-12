require 'importer'
require 'jsonmodel_queue'
require 'crosswalk'
require 'parse_queue'

if ENV['DISABLE_STARTUP'] != 'true'
  ASpaceImport::init

  import_dir = Rails.root.join('tmp', 'import')

  unless FileTest::directory?(import_dir)
    Dir::mkdir(import_dir)
  end
end
