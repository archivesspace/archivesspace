require 'spec_helper'
require 'rails_helper'

# The batch observer samples once per animation frame, so a fast scroll can
# carry a batch's trigger node across the observer zone unseen. These cover
# the scroll check that loads those skipped batches.
describe 'Collection Organization Tree fast scroll', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "tree_fast_scroll_#{Time.now.to_i}")
    set_repo(@repo)

    @resource = create(:resource, publish: true)
    @children = batch_create_archival_objects(240, resource: @resource) # 8 batches

    run_indexers
  end

  let(:batch_size) { Rails.configuration.tree_batch_size }
  let(:total_nodes) { @children.length }
  let(:total_batches) { (total_nodes / batch_size.to_f).ceil }
  let(:container) { find('#tree-container') }
  let(:root_list) { find("#resource_#{@resource.id}-children") }

  # Scrolls the container by `step` px per animation frame until it stops
  # moving, like a fast mouse wheel or a scrollbar drag
  def scroll_by_frame(container, step)
    page.evaluate_async_script(<<~JS, container, step)
      const [el, step, done] = arguments;
      let still = 0;
      (function frame() {
        const before = el.scrollTop;
        el.scrollTop += step;
        still = el.scrollTop === before ? still + 1 : 0;
        if (still >= 30) return done();
        requestAnimationFrame(frame);
      })();
    JS
  end

  it 'loads each batch when the tree jumps to its end' do
    visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"
    expect(root_list).to have_css('& > .node', minimum: batch_size)

    # Like the End key or a scrollbar drag to the bottom: one jump per frame
    (2..total_batches).each do |loaded_batches|
      container.execute_script('this.scrollTop = this.scrollHeight')
      expect(root_list).to have_css('& > .node', minimum: [loaded_batches * batch_size, total_nodes].min)
    end

    expect(root_list).to have_css('& > .node', count: total_nodes)
  end

  it 'loads the batches a fast scroll passes in both directions' do
    target = @children[149] # batch 5 of 8, so batches load above and below it
    visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization#tree::archival_object_#{target.id}"
    find("#archival_object_#{target.id}.current")

    # Each step is larger than the observer zone (twice the container height)
    scroll_by_frame(container, -2000)
    scroll_by_frame(container, 2000)

    expect(root_list).to have_css('& > .node', count: total_nodes)
    expect(root_list).not_to have_css('& > [data-batch-placeholder]', visible: :all)
  end
end
