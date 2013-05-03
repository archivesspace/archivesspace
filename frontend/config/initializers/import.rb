require 'csv'
require_relative '../../../migrations/lib/importer'
require_relative '../../../migrations/lib/utils'
require_relative '../../../migrations/lib/parse_queue'

if ENV['DISABLE_STARTUP'] != 'true'
  ASpaceImport::init

  import_dir = Rails.root.join('tmp', 'import')

  unless FileTest::directory?(import_dir)
    Dir::mkdir(import_dir)
  end
end
