require 'spec_helper'
require 'spec_helper_methods'
require 'stringio'

# This class was factored out of model_oai_spec for reuse in other tests where we need to
# prime the database with fixture data.

class OAIHelper
  FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "oai")

  def self.fake_job_monitor
    job_monitor = Object.new

    def job_monitor.method_missing(*)
      # Do nothing
    end

    job_monitor
  end

  def self.load_oai_data
    @oai_repo_id = RequestContext.open do
      FactoryBot.create(:repo, {:repo_code => "oai_test", :org_code => "oai", :name => "oai_test"}).id
    end

    test_subjects = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'subjects.json')))
    test_agents = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'agents.json')))

    test_resource_template = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'resource.json')))
    test_archival_object_template = ASUtils.json_parse(File.read(File.join(FIXTURES_DIR, 'archival_object.json')))

    # Create some test Resource records -- fully filled out with agents,
    # subjects and notes.
    @test_record_count = 5

    test_resources = @test_record_count.times.map do |i|
      resource = test_resource_template.clone
      resource['uri'] = "/repositories/2/resources/import_#{i}"
      resource['title'] = "Test resource #{i}"
      resource['id_0'] = "Resource OAI test #{i}"

      resource['ead_id'] = "ead_id_#{i}"
      resource['finding_aid_sponsor'] = "sponsor_#{i}"

      resource
    end

    # Create some Archival Object records -- same deal.
    test_archival_objects = @test_record_count.times.map do |i|
      archival_object = test_archival_object_template.clone
      archival_object['uri'] = "/repositories/2/archival_objects/import_#{SecureRandom.hex}"
      archival_object['component_id'] = "ArchivalObject OAI test #{i}"
      archival_object['resource'] = {'ref' => test_resources.fetch(i).fetch('uri')}

      # Mark one of them with a different level for our set tests
      archival_object['level'] = ((i == 4) ? 'fonds' : 'file')

      archival_object
    end

    # Import the whole lot
    test_data = StringIO.new(ASUtils.to_json(test_subjects +
                                             test_agents +
                                             test_resources +
                                             test_archival_objects))

    RequestContext.open(:repo_id => @oai_repo_id) do
      created_records = SpecHelperMethods::as_test_user('admin') do
        StreamingImport.new(test_data, fake_job_monitor, false, false).process
      end

      @test_resource_record = created_records.fetch(test_resources[0]['uri'])
      @test_archival_object_record = created_records.fetch(test_archival_objects[0]['uri'])

      SpecHelperMethods::as_test_user('admin') do
        # Prepare some deletes
        5.times do
          ao = FactoryBot.create(:json_archival_object)

          ArchivalObject[ao.id].delete
        end
      end
    end

    return [@oai_repo_id, @test_record_count, @test_resource_record, @test_archival_object_record]
  end
end

