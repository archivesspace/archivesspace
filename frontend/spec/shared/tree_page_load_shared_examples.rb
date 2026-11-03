# frozen_string_literal: true

RSpec.shared_examples 'normalizing invalid location hashes on the show view' do
  context 'when the location hash is invalid' do
    context 'with a malformed hash' do
      it 'rewrites the hash to root, rendering the tree root as the current node' do
        visit "#{show_path}#invalid_hash"
        wait_for_infinite_tree_loaded

        aggregate_failures do
          expect(page.current_url).to match(
            %r{#{Regexp.escape(show_path)}#tree::#{root_type}_#{root_id}}
          )
          expect(page).to have_css('#infinite-tree-container .infinite-tree .root.current')
          expect(page).to have_css(
            '#infinite-tree-container .node.current',
            count: 1,
            visible: :all
          )
        end
      end
    end

    context 'with valid shape but non-existent record id' do
      it 'renders the tree for the root and shows error in the record pane' do
        visit "#{show_path}#tree::#{child_type}_999999"

        aggregate_failures do
          expect(page).to have_css('#infinite-tree-container .infinite-tree .root')
          expect(page).not_to have_css(
            '#infinite-tree-container .current',
            visible: :all
          )
          expect(page).to have_css(
            '#infinite-tree-record-pane .alert.alert-danger',
            text: 'Record Not Found'
          )
        end
      end
    end
  end
end
