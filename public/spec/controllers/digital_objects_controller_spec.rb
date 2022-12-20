require 'spec_helper'

describe DigitalObjectsController, type: :controller do
  before(:all) do
    @repo = create(:repo, repo_code: "do_test_#{Time.now.to_i}",
                          publish: true)
    set_repo @repo

    @do = create(:digital_object, publish: true)
    @unpublished_do = create(:digital_object)
    @doc1 = create(:digital_object_component,
                   publish: true, digital_object: { ref: @do.uri })
    @doc2 = create(:digital_object_component,
                   publish: true, digital_object: { ref: @do.uri })
    @doc3 = create(:digital_object_component,
                   publish: true, digital_object: { ref: @do.uri })

    @grandchildren = (0..10).map do
      create(:digital_object_component,
             publish: true,
             digital_object: { ref: @do.uri },
             parent: { ref: [@doc1, @doc2, @doc3].sample.uri })
    end

    @great_grandchildren = @grandchildren.map do |gc|
      (0..3).map do
        create(:digital_object_component,
               publish: true,
               digital_object: { ref: @do.uri },
               parent: { ref: gc.uri })
      end
    end.flatten

    run_indexers
  end


  describe 'Tree Node Actions' do
    it 'should get the tree root' do
      get(:tree_root, params: { rid: @repo.id, id: @do.id })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree root' do
      get(:tree_root, params: { rid: @repo.id, id: 'notaId' })
      expect(response.status).to eq(404)
    end

    it 'should get the tree node for an Digital Object Component' do
      get(:tree_node, params: { rid: @repo.id, id: @do.id,
                                node: @doc1.uri })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the Node' do
      get(:tree_node, params: { rid: @repo.id, id: @do.id,
                                node: @do.uri })
      expect(response.status).to eq(404)
    end

    it 'should get the tree waypoint for a digital object' do
      get(:tree_waypoint, params: { rid: @repo.id, id: @do.id,
                                    node: nil, offset: 0 })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree waypoint' do
      get(:tree_waypoint, params: { rid: @repo.id, id: @do.id,
                                node: @do.uri, offset: 100 })
      expect(response.status).to eq(404)
    end

    it 'should get the tree node from the root' do
      get(:tree_node_from_root, params: { rid: @repo.id, id: @do.id,
                                          node_ids: [@doc1, @doc2, @doc3].map(&:id) })
      expect(response.status).to eq(200)
    end

    it 'should return a 404 when it cannot find the tree node from root' do
      get(:tree_node_from_root, params: { rid: @repo.id, id: @do.id,
                                          node_ids: ['notaId'] })
      expect(response.status).to eq(404)
    end
  end

  describe "Digital Object" do
    render_views

    img_uri = 'http://foo.com/image.jpg'

    before(:all) do
      @do2 = create(:digital_object, publish: true, :file_versions => [
        build(:file_version, {
          :publish => true,
          :is_representative => true,
          :file_uri => img_uri,
          :use_statement => 'image-service'
        })
      ])

      run_indexers
    end

    it 'should render the representative file version image when one is set' do
      get(:tree_root, params: { rid: @repo.id, id: @do2.id })

      expect(response.body).to match(img_uri)
    end

  end

end
