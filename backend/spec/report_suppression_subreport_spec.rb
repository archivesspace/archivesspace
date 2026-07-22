require 'spec_helper'

describe 'Report suppression filtering, subreports' do
  def parent_report(db, include_suppressed, record_type)
    double('ParentReport',
           repo_id: $repo_id,
           db: db,
           job: double('Job', write_output: nil),
           format: 'html',
           include_suppressed: include_suppressed,
           record_type: record_type,
           subreports: [])
  end

  def subreport_rows(subreport_class, *args, include_suppressed: false, record_type: nil)
    DB.open do |db|
      subreport = subreport_class.new(parent_report(db, include_suppressed, record_type), *args)
      db.fetch(subreport.query_string).map(&:to_hash)
    end
  end

  shared_examples 'a subreport that omits suppressed records by default' do
    it 'drops the record once suppressed and reports it again when include_suppressed is set' do
      expect(reported_values)
        .to include(expected_value), 'expected the linked record to be reported before it is suppressed'

      record_to_suppress.set_suppressed(true)

      expect(reported_values).to_not include(expected_value)
      expect(reported_values(include_suppressed: true)).to include(expected_value)
    end
  end

  describe 'the include_suppressed setting' do
    let(:report) do
      AccessionReport.new({ repo_id: $repo_id, format: 'html', 'include_suppressed' => '1' },
                          double('Job', write_output: nil),
                          nil)
    end

    it 'is inherited from the report that spawned the subreport' do
      subreport = AccessionResourcesSubreport.new(report, 1)

      expect(subreport.include_suppressed).to eq('1')
    end

    it 'is inherited through nested subreports' do
      nested = LocationAccessionsContainersSubreport.new(
        LocationAccessionsSubreport.new(report, 1), 1, 2)

      expect(nested.include_suppressed).to eq('1')
    end

    it 'is off by default, so the filters are applied' do
      subreport = AccessionResourcesSubreport.new(
        AccessionReport.new({ repo_id: $repo_id, format: 'html' }, double('Job'), nil), 1)

      expect(subreport.include_suppressed).to be_falsey
      expect(subreport.suppressed_filter('resource'))
        .to eq(' AND ifnull(resource.suppressed, 0) = 0')
    end
  end

  describe AccessionResourcesSubreport do
    let(:accession) { Accession.create_from_json(build(:json_accession), repo_id: $repo_id) }
    let(:expected_value) { "Spawned Resource #{SecureRandom.hex(6)}" }
    let!(:resource) do
      Resource.create_from_json(
        build(:json_resource,
              title: expected_value,
              related_accessions: [{ 'ref' => accession.uri }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { resource }

    def reported_values(include_suppressed: false)
      subreport_rows(AccessionResourcesSubreport, accession.id,
                     include_suppressed: include_suppressed).map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe AccessionLinkedAccessionsSubreport do
    let(:related) { Accession.create_from_json(build(:json_accession), repo_id: $repo_id) }
    let!(:accession) do
      Accession.create_from_json(
        build(:json_accession,
              related_accessions: [{ 'ref' => related.uri,
                                     'relator' => 'sibling_of',
                                     'relator_type' => 'bound_with',
                                     'jsonmodel_type' => 'accession_sibling_relationship' }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { related }
    let(:expected_value) { related.identifier }

    def reported_values(include_suppressed: false)
      subreport_rows(AccessionLinkedAccessionsSubreport, accession.id,
                     include_suppressed: include_suppressed)
        .flat_map { |row| [row[:id0], row[:id1]] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe AccessionClassificationsSubreport do
    let(:expected_value) { "Suppressible Classification #{SecureRandom.hex(6)}" }
    let(:classification) do
      Classification.create_from_json(build(:json_classification, title: expected_value),
                                      repo_id: $repo_id)
    end
    let!(:accession) do
      Accession.create_from_json(
        build(:json_accession, classifications: [{ 'ref' => classification.uri }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { classification }

    def reported_values(include_suppressed: false)
      subreport_rows(AccessionClassificationsSubreport, accession.id,
                     include_suppressed: include_suppressed).map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe ClassificationSubreport do
    let(:expected_value) { "Suppressible Classification #{SecureRandom.hex(6)}" }
    let(:classification) do
      Classification.create_from_json(build(:json_classification, title: expected_value),
                                      repo_id: $repo_id)
    end
    let!(:accession) do
      Accession.create_from_json(
        build(:json_accession, classifications: [{ 'ref' => classification.uri }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { classification }

    def reported_values(include_suppressed: false)
      subreport_rows(ClassificationSubreport, accession.id,
                     include_suppressed: include_suppressed,
                     record_type: 'accession').map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe ClassificationTermSubreport do
    let(:classification) do
      Classification.create_from_json(build(:json_classification), repo_id: $repo_id)
    end
    let(:expected_value) { "Suppressible Term #{SecureRandom.hex(6)}" }
    let!(:term) do
      ClassificationTerm.create_from_json(
        build(:json_classification_term,
              title: expected_value,
              classification: { 'ref' => classification.uri }),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { term }

    def reported_values(include_suppressed: false)
      subreport_rows(ClassificationTermSubreport, classification.id,
                     include_suppressed: include_suppressed).map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe AssessmentLinkedRecordsSubreport do
    def reported_values(include_suppressed: false)
      subreport_rows(AssessmentLinkedRecordsSubreport, assessment.id,
                     include_suppressed: include_suppressed).map { |row| row[:record_title] }
    end

    def assessment_for(uri)
      Assessment.create_from_json(build(:json_assessment, records: [{ 'ref' => uri }]),
                                  repo_id: $repo_id)
    end

    describe 'a linked resource' do
      let(:expected_value) { "Suppressible Resource #{SecureRandom.hex(6)}" }
      let(:resource) do
        Resource.create_from_json(build(:json_resource, title: expected_value), repo_id: $repo_id)
      end
      let!(:assessment) { assessment_for(resource.uri) }
      let(:record_to_suppress) { resource }

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe 'a linked archival object' do
      let(:expected_value) { "Suppressible Archival Object #{SecureRandom.hex(6)}" }
      let(:archival_object) do
        ArchivalObject.create_from_json(build(:json_archival_object, title: expected_value),
                                        repo_id: $repo_id)
      end
      let!(:assessment) { assessment_for(archival_object.uri) }
      let(:record_to_suppress) { archival_object }

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe 'a linked accession' do
      let(:expected_value) { "Suppressible Accession #{SecureRandom.hex(6)}" }
      let(:accession) do
        Accession.create_from_json(build(:json_accession, title: expected_value), repo_id: $repo_id)
      end
      let!(:assessment) { assessment_for(accession.uri) }
      let(:record_to_suppress) { accession }

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe 'a linked digital object' do
      let(:expected_value) { "Suppressible Digital Object #{SecureRandom.hex(6)}" }
      let(:digital_object) do
        DigitalObject.create_from_json(build(:json_digital_object, title: expected_value),
                                       repo_id: $repo_id)
      end
      let!(:assessment) { assessment_for(digital_object.uri) }
      let(:record_to_suppress) { digital_object }

      it_behaves_like 'a subreport that omits suppressed records by default'
    end
  end

  describe DigitalObjectFileVersionsListSubreport do
    let(:digital_object) do
      DigitalObject.create_from_json(
        build(:json_digital_object, file_versions: [build(:json_file_version)]),
        repo_id: $repo_id)
    end
    let(:expected_value) { "Suppressible Component #{SecureRandom.hex(6)}" }
    let!(:component) do
      DigitalObjectComponent.create_from_json(
        build(:json_digital_object_component,
              title: expected_value,
              digital_object: { 'ref' => digital_object.uri },
              file_versions: [build(:json_file_version)]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { component }

    def reported_values(include_suppressed: false)
      subreport_rows(DigitalObjectFileVersionsListSubreport, digital_object.id,
                     include_suppressed: include_suppressed)
        .map { |row| row[:digital_object_component_title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'

    it 'still reports the file versions of the unsuppressed digital object' do
      component.set_suppressed(true)

      expect(subreport_rows(DigitalObjectFileVersionsListSubreport, digital_object.id))
        .to_not be_empty
    end
  end

  describe EventSubreport do
    let(:accession) { Accession.create_from_json(build(:json_accession), repo_id: $repo_id) }
    let!(:event) do
      Event.create_from_json(
        build(:json_event,
              linked_records: [{ 'ref' => accession.uri, 'role' => 'source' }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { event }
    let(:expected_value) { event.id }

    def reported_values(include_suppressed: false)
      subreport_rows(EventSubreport, accession.id,
                     include_suppressed: include_suppressed,
                     record_type: 'accession').map { |row| row[:id] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe LinkedAccessionSubreport do
    let(:expected_value) { "Suppressible Accession #{SecureRandom.hex(6)}" }
    let(:accession) do
      Accession.create_from_json(build(:json_accession, title: expected_value), repo_id: $repo_id)
    end
    let!(:event) do
      Event.create_from_json(
        build(:json_event, linked_records: [{ 'ref' => accession.uri, 'role' => 'source' }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { accession }

    def reported_values(include_suppressed: false)
      subreport_rows(LinkedAccessionSubreport, event.id,
                     include_suppressed: include_suppressed,
                     record_type: 'event').map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe LinkedResourceSubreport do
    let(:expected_value) { "Suppressible Resource #{SecureRandom.hex(6)}" }
    let(:resource) do
      Resource.create_from_json(build(:json_resource, title: expected_value), repo_id: $repo_id)
    end
    let!(:event) do
      Event.create_from_json(
        build(:json_event, linked_records: [{ 'ref' => resource.uri, 'role' => 'source' }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { resource }

    def reported_values(include_suppressed: false)
      subreport_rows(LinkedResourceSubreport, event.id,
                     include_suppressed: include_suppressed,
                     record_type: 'event').map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe LinkedArchivalObjectSubreport do
    let(:expected_value) { "Suppressible Archival Object #{SecureRandom.hex(6)}" }
    let(:archival_object) do
      ArchivalObject.create_from_json(build(:json_archival_object, title: expected_value),
                                      repo_id: $repo_id)
    end
    let!(:event) do
      Event.create_from_json(
        build(:json_event, linked_records: [{ 'ref' => archival_object.uri, 'role' => 'source' }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { archival_object }

    def reported_values(include_suppressed: false)
      subreport_rows(LinkedArchivalObjectSubreport, event.id,
                     include_suppressed: include_suppressed,
                     record_type: 'event').map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe LinkedDigitalObjectSubreport do
    let(:expected_value) { "Suppressible Digital Object #{SecureRandom.hex(6)}" }
    let(:digital_object) do
      DigitalObject.create_from_json(build(:json_digital_object, title: expected_value),
                                     repo_id: $repo_id)
    end
    let!(:event) do
      Event.create_from_json(
        build(:json_event, linked_records: [{ 'ref' => digital_object.uri, 'role' => 'source' }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { digital_object }

    def reported_values(include_suppressed: false)
      subreport_rows(LinkedDigitalObjectSubreport, event.id,
                     include_suppressed: include_suppressed,
                     record_type: 'event').map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe LinkedDigitalObjectComponentSubreport do
    let(:expected_value) { "Suppressible Component #{SecureRandom.hex(6)}" }
    let(:component) do
      DigitalObjectComponent.create_from_json(build(:json_digital_object_component,
                                                    title: expected_value),
                                              repo_id: $repo_id)
    end
    let!(:event) do
      Event.create_from_json(
        build(:json_event, linked_records: [{ 'ref' => component.uri, 'role' => 'source' }]),
        repo_id: $repo_id)
    end
    let(:record_to_suppress) { component }

    def reported_values(include_suppressed: false)
      subreport_rows(LinkedDigitalObjectComponentSubreport, event.id,
                     include_suppressed: include_suppressed,
                     record_type: 'event').map { |row| row[:title] }
    end

    it_behaves_like 'a subreport that omits suppressed records by default'
  end

  describe 'location and container subreports' do
    let(:location) { create(:json_location) }
    let(:top_container) do
      create(:json_top_container,
             container_locations: [{ 'ref' => location.uri,
                                     'status' => 'current',
                                     'start_date' => generate(:yyyy_mm_dd) }])
    end
    let(:instance) do
      build(:json_instance,
            instance_type: 'text',
            sub_container: build(:json_sub_container,
                                 top_container: { 'ref' => top_container.uri }))
    end

    describe LocationAccessionsSubreport do
      let(:expected_value) { "Suppressible Accession #{SecureRandom.hex(6)}" }
      let!(:accession) do
        Accession.create_from_json(
          build(:json_accession, title: expected_value, instances: [instance]),
          repo_id: $repo_id)
      end
      let(:record_to_suppress) { accession }

      def reported_values(include_suppressed: false)
        subreport_rows(LocationAccessionsSubreport, Location[location.id].id,
                       include_suppressed: include_suppressed).map { |row| row[:title] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe LocationResourcesSubreport do
      let(:expected_value) { "Suppressible Resource #{SecureRandom.hex(6)}" }
      let!(:resource) do
        Resource.create_from_json(
          build(:json_resource, title: expected_value, instances: [instance]),
          repo_id: $repo_id)
      end
      let(:record_to_suppress) { resource }

      def reported_values(include_suppressed: false)
        subreport_rows(LocationResourcesSubreport, Location[location.id].id,
                       include_suppressed: include_suppressed).map { |row| row[:title] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'

      describe 'when the instance hangs off an archival object' do
        let(:resource) do
          Resource.create_from_json(build(:json_resource, title: expected_value), repo_id: $repo_id)
        end
        let!(:archival_object) do
          ArchivalObject.create_from_json(
            build(:json_archival_object,
                  resource: { 'ref' => resource.uri },
                  instances: [instance]),
            repo_id: $repo_id)
        end
        let(:record_to_suppress) { archival_object }

        it_behaves_like 'a subreport that omits suppressed records by default'
      end
    end

    describe ContainerResourcesAccessionsSubreport do
      def reported_values(include_suppressed: false)
        subreport_rows(ContainerResourcesAccessionsSubreport, TopContainer[top_container.id].id,
                       include_suppressed: include_suppressed).map { |row| row[:record_title] }
      end

      describe 'a linked accession' do
        let(:expected_value) { "Suppressible Accession #{SecureRandom.hex(6)}" }
        let!(:accession) do
          Accession.create_from_json(
            build(:json_accession, title: expected_value, instances: [instance]),
            repo_id: $repo_id)
        end
        let(:record_to_suppress) { accession }

        it_behaves_like 'a subreport that omits suppressed records by default'
      end

      describe 'a linked resource' do
        let(:expected_value) { "Suppressible Resource #{SecureRandom.hex(6)}" }
        let!(:resource) do
          Resource.create_from_json(
            build(:json_resource, title: expected_value, instances: [instance]),
            repo_id: $repo_id)
        end
        let(:record_to_suppress) { resource }

        it_behaves_like 'a subreport that omits suppressed records by default'
      end

      describe 'a resource reached through an archival object' do
        let(:expected_value) { "Suppressible Resource #{SecureRandom.hex(6)}" }
        let(:resource) do
          Resource.create_from_json(build(:json_resource, title: expected_value), repo_id: $repo_id)
        end
        let!(:archival_object) do
          ArchivalObject.create_from_json(
            build(:json_archival_object,
                  resource: { 'ref' => resource.uri },
                  instances: [instance]),
            repo_id: $repo_id)
        end
        let(:record_to_suppress) { archival_object }

        it_behaves_like 'a subreport that omits suppressed records by default'
      end
    end

    describe ResourceLocationsSubreport do
      let(:resource) { Resource.create_from_json(build(:json_resource), repo_id: $repo_id) }
      let!(:archival_object) do
        ArchivalObject.create_from_json(
          build(:json_archival_object,
                resource: { 'ref' => resource.uri },
                instances: [instance]),
          repo_id: $repo_id)
      end
      let(:record_to_suppress) { archival_object }
      let(:expected_value) { Location[location.id].title }

      def reported_values(include_suppressed: false)
        subreport_rows(ResourceLocationsSubreport, resource.id,
                       include_suppressed: include_suppressed).map { |row| row[:location] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe ResourceInstancesSubreport do
      let(:resource) { Resource.create_from_json(build(:json_resource), repo_id: $repo_id) }
      let!(:archival_object) do
        ArchivalObject.create_from_json(
          build(:json_archival_object,
                resource: { 'ref' => resource.uri },
                instances: [instance]),
          repo_id: $repo_id)
      end
      let(:record_to_suppress) { archival_object }
      let(:expected_value) { TopContainer[top_container.id].indicator }

      def reported_values(include_suppressed: false)
        subreport_rows(ResourceInstancesSubreport, resource.id,
                       include_suppressed: include_suppressed).map { |row| row[:indicator_1] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe LocationResourcesContainersSubreport do
      let(:resource) { Resource.create_from_json(build(:json_resource), repo_id: $repo_id) }
      let!(:archival_object) do
        ArchivalObject.create_from_json(
          build(:json_archival_object,
                resource: { 'ref' => resource.uri },
                instances: [instance]),
          repo_id: $repo_id)
      end
      let(:record_to_suppress) { archival_object }
      let(:expected_value) { TopContainer[top_container.id].indicator }

      def reported_values(include_suppressed: false)
        subreport_rows(LocationResourcesContainersSubreport,
                       Location[location.id].id, resource.id,
                       include_suppressed: include_suppressed).map { |row| row[:indicator] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'
    end
  end

  # The instances subreports roll the titles of any linked digital objects into
  # a single column, which leaked suppressed digital objects the same way.
  describe 'digital objects linked to an instance' do
    let(:expected_value) { "Suppressible Digital Object #{SecureRandom.hex(6)}" }
    let(:digital_object) do
      DigitalObject.create_from_json(build(:json_digital_object, title: expected_value),
                                     repo_id: $repo_id)
    end
    let(:instance) do
      build(:json_instance,
            instance_type: 'digital_object',
            digital_object: { 'ref' => digital_object.uri },
            sub_container: nil)
    end
    let(:record_to_suppress) { digital_object }

    describe AccessionInstancesSubreport do
      let!(:accession) do
        Accession.create_from_json(build(:json_accession, instances: [instance]),
                                   repo_id: $repo_id)
      end

      def reported_values(include_suppressed: false)
        subreport_rows(AccessionInstancesSubreport, accession.id,
                       include_suppressed: include_suppressed).map { |row| row[:digital_object] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe ArchivalObjectInstancesSubreport do
      let!(:archival_object) do
        ArchivalObject.create_from_json(build(:json_archival_object, instances: [instance]),
                                        repo_id: $repo_id)
      end

      def reported_values(include_suppressed: false)
        subreport_rows(ArchivalObjectInstancesSubreport, archival_object.id,
                       include_suppressed: include_suppressed).map { |row| row[:digital_object] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'
    end

    describe ResourceInstancesSubreport do
      let!(:resource) do
        Resource.create_from_json(build(:json_resource, instances: [instance]), repo_id: $repo_id)
      end

      def reported_values(include_suppressed: false)
        subreport_rows(ResourceInstancesSubreport, resource.id,
                       include_suppressed: include_suppressed).map { |row| row[:digital_object] }
      end

      it_behaves_like 'a subreport that omits suppressed records by default'
    end
  end
end
