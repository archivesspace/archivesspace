require 'spec_helper'

describe ResourcesController, type: :controller do
  before(:all) do
    @repo = create(:repo, repo_code: "resources_test_#{Time.now.to_i}",
                          publish: true)
    set_repo @repo
    @accession = create(:accession,
                        collection_management: build(:collection_management))

    @resource = create(:resource, publish: true)
    @unpublished_resource = create(:resource)

    @a1 = create(:archival_object,
                 publish: true, resource: { ref: @resource.uri })
    @a2 = create(:archival_object,
                 publish: true, resource: { ref: @resource.uri })
    @a3 = create(:archival_object,
                 publish: true, resource: { ref: @resource.uri })

    @grandchildren = (0..10).map do
      create(:archival_object,
             publish: true,
             resource: { ref: @resource.uri },
             parent: { ref: [@a1, @a2, @a3].sample.uri })
    end

    @great_grandchildren = @grandchildren.map do |gc|
      (0..3).map do
        create(:archival_object,
               publish: true,
               resource: { ref: @resource.uri },
               parent: { ref: gc.uri })
      end
    end.flatten

    run_all_indexers
  end

  it 'should show the published resources' do
    expect(get(:index)).to have_http_status(200)
    results = assigns(:results)
    expect(results['total_hits']).to eq(4)
    expect(results.records.first['title']).to eq("Published Resource")
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
                                          node_ids: [@a1,@a2,@a3].map(&:id) })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree node from root' do
      get(:tree_node_from_root, params: { rid: @repo.id, id: @resource.id,
                                          node_ids: ['notaId'] })
      expect(response.status).to eq(404)
    end
  end
end
