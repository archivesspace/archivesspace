require 'jsonmodel'
require 'client_enum_source'
JSONModel::init(:client_mode => false, :strict_mode => false, :enum_source => ClientEnumSource.new)
include JSONModel

