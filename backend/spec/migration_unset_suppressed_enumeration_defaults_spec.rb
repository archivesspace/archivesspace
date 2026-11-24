require 'spec_helper'

describe 'Migration 184: unset suppressed enumeration defaults' do
  let(:migration) {
    migration_file = File.join(File.dirname(__FILE__), '../../common/db/migrations/184_unset_suppressed_enumeration_defaults.rb')
    eval(File.read(migration_file), TOPLEVEL_BINDING, migration_file)
  }

  def list_with_default(name, suppressed:)
    enumeration = Enumeration.create_from_json(JSONModel(:enumeration).from_hash(:name => name, :values => ['first', 'second']))
    default = EnumerationValue[:enumeration_id => enumeration.id, :value => 'first']
    $testdb[:enumeration_value].filter(:id => default.id).update(:suppressed => suppressed ? 1 : 0)
    $testdb[:enumeration].filter(:id => enumeration.id).update(:default_value => default.id)

    enumeration.id
  end

  it 'unsets suppressed defaults and keeps unsuppressed ones' do
    suppressed_default = list_with_default('suppressed_default_enum', :suppressed => true)
    unsuppressed_default = list_with_default('unsuppressed_default_enum', :suppressed => false)

    migration.apply($testdb, :up)

    expect(Enumeration[suppressed_default].default_value).to be_nil
    expect(Enumeration[unsuppressed_default].default_value).not_to be_nil
  end
end
