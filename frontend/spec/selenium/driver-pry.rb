require_relative 'spec/spec_helper'

include BackendClientMethods
# include DriverMacroMethods
include TreeHelperMethods
include FactoryBot::Syntax::Methods

selenium_init($backend_start_fn, $frontend_start_fn)
SeleniumFactories.init

$indexer = RealtimeIndexer.new($backend, nil)
$period = PeriodicIndexer.new

$admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
$driver = Driver.get

