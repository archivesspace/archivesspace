require 'spec_helper'

describe ResourcesController, type: :controller do
  render_views

  before(:all) do
    @fv_uri = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
    @fv_caption = 'digital_object_with_rep_file_ver caption'

    @repo = create(:repo, repo_code: "resources_test_#{Time.now.to_i}",
                          publish: true)
    set_repo @repo
    @accession = create(:accession,
                        collection_management: build(:collection_management))
    @digital_object = create(:digital_object)
    @digital_object_with_rep_file_ver = create(:digital_object,
      publish: true,
      title: 'Digital object with representative file version',
      :file_versions => [build(:file_version, {
        :publish => true,
        :is_representative => true,
        :file_uri => @fv_uri,
        :caption => @fv_caption,
        :use_statement => 'image-service'
      })]
    )
    @resource = create(:resource, publish: true,
                       instances: [build(:instance_digital, digital_object: { ref: @digital_object.uri })])
    @resource_with_rep_instance = create(:resource,
      publish: true,
      title: "Resource with representative file version",
      instances: [build(:instance_digital,
        digital_object: {'ref' => @digital_object_with_rep_file_ver.uri},
        is_representative: true
      )]
    )
    @resource_with_rep_instance_2 = create(:resource,
      publish: true,
      title: "Yet another Resource with representative file version",
      instances: [build(:instance_digital,
        digital_object: {'ref' => @digital_object_with_rep_file_ver.uri},
        is_representative: true
      )]
    )
    @unpublished_resource = create(:resource)

    subject = create(:subject, terms: [build(:term, {term: 'Term 1', term_type: 'temporal'}), build(:term, term: 'Term 2')])
    @resource_with_subj = create(:resource, title: "Resource with Subject from Controller",
                    publish: true,
                    instances: [build(:instance_digital)],
                    subjects: [{'ref' => subject.uri}])

    @a1 = create(:archival_object,
                 publish: true, resource: { ref: @resource.uri })
    @a2 = create(:archival_object,
                 publish: true, resource: { ref: @resource.uri })
    @a3 = create(:archival_object,
                 publish: true, resource: { ref: @resource.uri })

    archival_objects = [ @a1, @a2, @a3 ]
    @grandchildren = (0..10).map do |i|
      create(:archival_object,
             publish: true,
             resource: { ref: @resource.uri },
             parent: { ref: archival_objects[i/4].uri })
    end

    @great_grandchildren = @grandchildren.map do |gc|
      (0..3).map do
        create(:archival_object,
               publish: true,
               resource: { ref: @resource.uri },
               parent: { ref: gc.uri })
      end
    end.flatten

    run_indexers
  end

  it 'should show the published resources' do
    expect(get(:index)).to have_http_status(200)
    results = assigns(:results)
    expect(results['total_hits']).to be > 3
  end

  it 'should display subjects organized by type' do
    get(:show, params: {rid: @repo.id, id: @resource_with_subj.id})

    expect(response.body).to match('Temporal')
    expect(response.body).to match('Term 1 -- Term 2')
  end

  describe 'Tree Node Actions' do
    it 'should get the tree root' do
      get(:tree_root, params: { rid: @repo.id, id: @resource.id })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree root' do
      get(:tree_root, params: { rid: @repo.id, id: 'notaId' })
      expect(response.status).to eq(404)
    end

    it 'should get the tree node for an Archival Object' do
      get(:tree_node, params: { rid: @repo.id, id: @resource.id,
                                node: @a1.uri })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the Node' do
      get(:tree_node, params: { rid: @repo.id, id: @resource.id,
                                node: @resource.uri })
      expect(response.status).to eq(404)
    end

    it 'should get the tree waypoint for an Archival Object' do
      get(:tree_waypoint, params: { rid: @repo.id, id: @resource.id,
                                    node: nil, offset: 0 })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree waypoint' do
      get(:tree_waypoint, params: { rid: @repo.id, id: @resource.id,
                                node: @resource.uri, offset: 100 })
      expect(response.status).to eq(404)
    end

    it 'should get the tree node from the root ' do
      get(:tree_node_from_root, params: { rid: @repo.id, id: @resource.id,
                                          node_ids: [@a1, @a2, @a3].map(&:id) })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree node from root' do
      get(:tree_node_from_root, params: { rid: @repo.id, id: @resource.id,
                                          node_ids: ['notaId'] })
      expect(response.status).to eq(404)
    end
  end

  describe "show action" do
    it "passes digital object instance data to the view" do
      get(:show, params: { rid: @repo.id, id: @resource.id })
      instance_data = controller.instance_variable_get(:@dig)
      expect(instance_data[0]['caption']).to eq(@digital_object.title)
    end

    it 'displays a representative file version image, caption and link to view all digital objects when set' do
      get(:show, params: {rid: @repo.id, id: @resource_with_rep_instance.id})

      expect(response).to render_template("shared/_representative_file_version_record")
      page = Capybara.string(response.body)
      expect(page).to have_css("figure[data-rep-file-version-wrapper] img[src='#{@fv_uri}']")
      page.find(:css, 'figure[data-rep-file-version-wrapper] figcaption') do |fc|
        expect(fc.text).to have_content(@fv_caption)
      end
      expect(response.body).to have_css(".objectimage a[data-view-all-digital-objects]")
    end
  end

  describe 'digitized action' do
    it 'displays tree breadcrumbs for digital objects linked to more than one Resource' do
      get(:digitized, params: {rid: @repo.id, id: @resource_with_rep_instance.id})

      page = Capybara.string(response.body)

      page.find(:css, ".recordrow[data-uri='#{@digital_object_with_rep_file_ver.uri}'] ol.result_linked_instances_tree li:first-of-type span.resource_name") do |span|
        expect(span).to have_content @resource_with_rep_instance.title
      end

      page.find(:css, ".recordrow[data-uri='#{@digital_object_with_rep_file_ver.uri}'] ol.result_linked_instances_tree li:last-of-type span.resource_name") do |span|
        expect(span).to have_content @resource_with_rep_instance_2.title
      end
    end
  end
end
