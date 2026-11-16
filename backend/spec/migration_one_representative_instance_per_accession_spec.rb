require 'spec_helper'

describe 'Migration 183: one representative instance per accession', :disable_database_transaction do
  let(:migration) {
    migration_file = File.join(File.dirname(__FILE__), '../../common/db/migrations/183_one_representative_instance_per_accession.rb')
    eval(File.read(migration_file), TOPLEVEL_BINDING, migration_file)
  }

  let(:long_ago) { Time.utc(2000, 1, 1) }
  let(:accessions) { [] }
  let(:digital_objects) { [] }

  around do |example|
    DB.open { |db| db.alter_table(:instance) { drop_constraint(:accession_one_representative_instance, :type => :unique) } }
    example.run
  ensure
    DB.open do |db|
      unless db.indexes(:instance).key?(:accession_one_representative_instance)
        db.alter_table(:instance) { add_unique_constraint([:is_representative, :accession_id], :name => 'accession_one_representative_instance') }
      end
    end
  end

  after do
    accessions.each { |accession| Accession[accession.id].delete }
    digital_objects.each { |digital_object| DigitalObject[digital_object.id].delete }
  end

  def accession(*representative_flags)
    instances = representative_flags.map {
      digital_objects << create(:json_digital_object)
      build(:json_instance_digital, :digital_object => {'ref' => digital_objects.last.uri})
    }
    accessions << create(:json_accession, :instances => instances)

    instance_ids = Accession[accessions.last.id].instance.map(&:id).sort
    DB.open do |db|
      instance_ids.zip(representative_flags).each do |id, flag|
        db[:instance].filter(:id => id).update(:is_representative => flag ? 1 : nil)
      end
      db[:accession].filter(:id => accessions.last.id).update(:system_mtime => long_ago)
    end

    accessions.last
  end

  def representative_flags(accession)
    Accession.to_jsonmodel(accession.id)['instances'].map { |instance| instance['is_representative'] }
  end

  def touched?(accession)
    Accession[accession.id].system_mtime > long_ago
  end

  it 'keeps only the first representative instance of an accession that has several' do
    several = accession(false, true, false, true)
    identifier = [0, 1, 2, 3].map { |part| several["id_#{part}"] }.compact.join('-')

    expect {
      DB.open { |db| migration.apply(db, :up) }
    }.to output(%r{^  #{Regexp.escape(several.uri)} #{Regexp.escape(identifier)}$}).to_stderr

    expect(representative_flags(several)).to eq([false, true, false, false])
    expect(touched?(several)).to be true
  end

  it 'leaves accessions with one representative instance alone' do
    one = accession(true, false)

    expect {
      DB.open { |db| migration.apply(db, :up) }
    }.not_to output(/#{Regexp.escape(one.uri)}/).to_stderr

    expect(representative_flags(one)).to eq([true, false])
    expect(touched?(one)).to be false
  end

  it 'adds the constraint' do
    DB.open { |db| migration.apply(db, :up) }

    expect(DB.open { |db| db.indexes(:instance)[:accession_one_representative_instance] }).to include(:unique => true)
  end
end
