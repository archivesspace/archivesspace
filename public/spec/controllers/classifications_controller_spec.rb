require 'spec_helper'

describe ClassificationsController, type: :controller do
  before(:all) do
    @repo = create(:repo, repo_code: "classification_test_#{Time.now.to_i}",
                          publish: true)
    set_repo @repo

    @creator = create(:agent_person)
    @classification = create(:classification, creator: { ref: @creator.uri },
                                              publish: true)

    @term1 = create(:classification_term,
                    publish: true, classification: { ref: @classification.uri })
    @term2 = create(:classification_term,
                    publish: true, classification: { ref: @classification.uri })
    @term3 = create(:classification_term,
                    publish: true, classification: { ref: @classification.uri })

    @grandchildren = (0..10).map do
      create(:classification_term,
             publish: true,
             classification: { ref: @classification.uri },
             parent: { ref: [@term1, @term2, @term3].sample.uri })
    end

    @great_grandchildren = @grandchildren.map do |gc|
      (0..3).map do
        create(:classification_term,
               publish: true,
               classification: { ref: @classification.uri },
               parent: { ref: gc.uri })
      end
    end.flatten

    run_all_indexers
  end

  it 'should show the published classification' do
    expect(get(:index)).to have_http_status(200)
    results = assigns(:results)
    expect(results['total_hits']).to eq(1)
    expect(results.records.first['title']).to eq(@classification['title'])
  end

  describe 'Tree Node Actions' do
    it 'should get the tree root' do
      get(:tree_root, params: { rid: @repo.id, id: @classification.id })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree root' do
      get(:tree_root, params: { rid: @repo.id, id: 'notaId' })
      expect(response.status).to eq(404)
    end

    it 'should get the tree node for an classification term' do
      get(:tree_node, params: { rid: @repo.id, id: @classification.id,
                                node: @term1.uri })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the Node' do
      get(:tree_node, params: { rid: @repo.id, id: @classification.id,
                                node: @classification.uri })
      expect(response.status).to eq(404)
    end

    it 'should get the tree waypoint for an classification' do
      get(:tree_waypoint, params: { rid: @repo.id, id: @classification.id,
                                    node: nil, offset: 0 })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree waypoint' do
      get(:tree_waypoint, params: { rid: @repo.id, id: @classification.id,
                                    node: @classification.uri, offset: 100 })
      expect(response.status).to eq(404)
    end

    it 'should get the tree node from the root ' do
      get(:tree_node_from_root, params: { rid: @repo.id, id: @classification.id,
                                          node_ids: [@term1, @term2, @term3]
                                          .map(&:id) })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree node from root' do
      get(:tree_node_from_root, params: { rid: @repo.id, id: @classification.id,
                                          node_ids: ['notaId'] })
      expect(response.status).to eq(404)
    end
  end
end
