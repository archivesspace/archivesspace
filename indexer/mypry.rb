require 'rubygems'
require 'sinatra/base'
require 'atomic'

require_relative 'app/lib/periodic_indexer'
require_relative 'app/lib/realtime_indexer'

$periodic_indexer = PeriodicIndexer.get_indexer
$periodic_indexer.login


include JSONModel
