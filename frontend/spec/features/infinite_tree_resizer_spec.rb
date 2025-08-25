# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Resizer', js: true do
  before(:each) do
    login_admin
    select_repository($repo)
  end

  context 'on a resource show page' do
    before(:each) do
      visit '/resources/1'
      page.execute_script('localStorage.removeItem("AS_Tree_Height")')
      @handle = find('#infinite-tree-resizer [data-resize-handle]')
      @toggle = find('#infinite-tree-resizer [data-resize-toggle]')
    end

    def tree_height
      evaluate_script(
        "parseInt(getComputedStyle(document.getElementById('infinite-tree-container')).height, 10)"
      )
    end

    def available_height
      maximized_margin_bottom = 50 # From InfiniteTreeResizer.js
      evaluate_script(
        "Math.floor(window.innerHeight - #{maximized_margin_bottom} - document.getElementById('infinite-tree-container').getBoundingClientRect().top)"
      )
    end

    def drag_handle_by(delta_y)
      # Keep handle in viewport before dragging to avoid out-of-bounds errors
      execute_script("arguments[0].scrollIntoView({block: 'center'})", @handle.native)

      page.driver.browser.action
        .click_and_hold(@handle.native)
        .move_by(0, delta_y)
        .release
        .perform
    end

    def expect_tree_height_matches_handle_value_now
      expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)
    end

    shared_examples 'persists tree height across page visits' do
      it 'persists the tree height after revisiting the page' do
        expected_height = tree_height

        page.refresh
        handle = find('#infinite-tree-resizer [data-resize-handle]')
        stored_height = evaluate_script("localStorage.getItem('AS_Tree_Height')")

        expect(stored_height.to_i).to eq(expected_height)
        expect(tree_height).to eq(expected_height)
        expect(handle[:'aria-valuenow'].to_i).to eq(expected_height)
      end
    end

    shared_examples 'maximized tree state' do
      it 'is maximized' do
        expect(tree_height).to eq(available_height)
        expect(tree_height).to eq(@handle[:'aria-valuemax'].to_i)
        expect(@handle).to match_css('.maximized')
        expect(@toggle[:'aria-expanded']).to eq('true')
      end
    end

    shared_examples 'minimized tree state' do
      it 'is minimized' do
        expect(tree_height).to eq(@handle[:'aria-valuemin'].to_i)
        expect(@handle).not_to match_css('.maximized')
        expect(@toggle[:'aria-expanded']).to eq('false')
      end
    end

    shared_examples 'key changes height by' do |key, delta|
      it "#{key} changes height by #{delta}" do
        start = @handle[:'aria-valuenow'].to_i
        @handle.send_keys(key)
        expect(@handle[:'aria-valuenow'].to_i).to eq(start + delta)
        expect_tree_height_matches_handle_value_now
      end
    end

    describe 'handle' do
      it 'includes expected ARIA attributes on page load' do
        expect(@handle[:'role']).to eq('separator')
        expect(@handle[:'aria-orientation']).to eq('horizontal')
        expect(@handle[:'tabindex']).to eq('0')
        expect(@handle[:'aria-valuemin']).to eq('60')
        expect(@handle[:'aria-valuemax'].to_i).to eq(available_height)
        expect_tree_height_matches_handle_value_now
      end

      describe 'mouse drag' do
        it 'changes tree height and updates aria-valuenow' do
          start_height = tree_height
          drag_handle_by(100)
          expect(tree_height).to eq(start_height + 100)
          expect_tree_height_matches_handle_value_now

          drag_handle_by(-50)
          expect(tree_height).to eq(start_height + 50)
          expect_tree_height_matches_handle_value_now
        end

        it 'does not go below min height when dragged upward beyond the minimum height' do
          # Compute a safe negative delta that would push the handle below min if it wasn't clamped
          min_h = @handle[:'aria-valuemin'].to_i
          current_h = tree_height
          desired_delta = -((current_h - min_h) + 20) # request an upward drag > distance to min by 20px (would go below min if not clamped)

          # Clamp upward movement so handle remains within viewport
          handle_y = @handle.native.rect.y
          safe_delta = [desired_delta, -(handle_y - 10)].max # clamp so handle stays within viewport (>=10px from top)

          drag_handle_by(safe_delta)

          expect(tree_height).to eq(min_h)
          expect_tree_height_matches_handle_value_now
        end

        context 'after resizing the tree' do
          before do
            drag_handle_by(80)
          end

          it_behaves_like 'persists tree height across page visits'
        end
      end

      describe 'keyboard controls' do
        context 'small step keys' do
          include_examples 'key changes height by', :arrow_up, 10
          include_examples 'key changes height by', :arrow_right, 10
          include_examples 'key changes height by', :arrow_down, -10
          include_examples 'key changes height by', :arrow_left, -10
        end

        context 'large step keys' do
          describe 'PageUp' do
            include_examples 'key changes height by', :page_up, 50
          end

          describe 'PageDown' do
            before { @handle.send_keys(:page_up) }
            include_examples 'key changes height by', :page_down, -50
          end
        end

        it 'Home minimizes' do
          @handle.send_keys(:home)
          expect(@handle[:'aria-valuenow'].to_i).to eq(@handle[:'aria-valuemin'].to_i)
          expect_tree_height_matches_handle_value_now
        end

        it 'End maximizes' do
          @handle.send_keys(:end)
          expect(@handle[:'aria-valuenow'].to_i).to eq(@handle[:'aria-valuemax'].to_i)
          expect_tree_height_matches_handle_value_now
        end

        it 'does not go below min or above max' do
          @handle.send_keys(:home, :arrow_down, :arrow_left, :page_down)
          expect(@handle[:'aria-valuenow'].to_i).to eq(@handle[:'aria-valuemin'].to_i)

          @handle.send_keys(:end, :arrow_up, :arrow_right, :page_up)
          expect(@handle[:'aria-valuenow'].to_i).to eq(@handle[:'aria-valuemax'].to_i)
        end

        it 'ignores unrelated keys' do
          start = @handle[:'aria-valuenow'].to_i
          @handle.send_keys('a')
          expect(@handle[:'aria-valuenow'].to_i).to eq(start)
        end

        context 'after resizing the tree' do
          before do
            @handle.send_keys(:arrow_up, :arrow_up, :arrow_up)
          end

          it_behaves_like 'persists tree height across page visits'
        end
      end
    end

    describe 'toggle' do
      it 'includes expected ARIA attributes on page load' do
        expect(@toggle[:'aria-expanded']).to eq('false')
      end

      describe 'click' do
        context 'when toggled on' do
          before { @toggle.click }

          it_behaves_like 'maximized tree state'
        end

        context 'when toggled off' do
          before do
            @toggle.click
            @toggle.click
          end

          it_behaves_like 'minimized tree state'
        end

        context 'after resizing the tree' do
          before { @toggle.click }

          it_behaves_like 'persists tree height across page visits'
        end
      end

      describe 'keyboard controls' do
        context 'Space' do
          describe 'toggle on' do
            before { @toggle.send_keys(:space) }

            it_behaves_like 'maximized tree state'
          end

          describe 'toggle off' do
            before do
              @toggle.send_keys(:space)
              @toggle.send_keys(:space)
            end

            it_behaves_like 'minimized tree state'
          end
        end

        context 'Enter' do
          describe 'toggle on' do
            before { @toggle.send_keys(:enter) }

            it_behaves_like 'maximized tree state'
          end

          describe 'toggle off' do
            before do
              @toggle.send_keys(:enter)
              @toggle.send_keys(:enter)
            end

            it_behaves_like 'minimized tree state'
          end
        end

        context 'Space and Enter' do
          describe 'toggle on' do
            before do
              @toggle.send_keys(:space)
              @toggle.send_keys(:enter)
              @toggle.send_keys(:space)
            end

            it_behaves_like 'maximized tree state'
          end

          describe 'toggle off' do
            before do
              @toggle.send_keys(:space)
              @toggle.send_keys(:enter)
            end

            it_behaves_like 'minimized tree state'
          end
        end

        context 'after resizing the tree' do
          before do
            @toggle.send_keys(:space)
          end

          it_behaves_like 'persists tree height across page visits'
        end
      end
    end

    describe 'window resize' do
      it 'updates aria-valuemax but not the tree height' do
        orig_w, orig_h = page.current_window.size
        before_height = tree_height

        begin
          initial_valuemax = @handle[:'aria-valuemax'].to_i

          # Decrease window size
          new_h = [orig_h - 200, 600].max
          page.current_window.resize_to(orig_w, new_h)

          # Pause for resize
          Timeout.timeout(2) do
            loop do
              break if @handle[:'aria-valuemax'].to_i == available_height
              sleep 0.05
            end
          end

          shrunk_valuemax = @handle[:'aria-valuemax'].to_i
          expect(shrunk_valuemax).to eq(available_height)
          expect(shrunk_valuemax).to be < initial_valuemax
          expect(tree_height).to eq(before_height)

          # Increase window size
          larger_h = orig_h + 400
          page.current_window.resize_to(orig_w, larger_h)

          Timeout.timeout(2) do
            loop do
              break if @handle[:'aria-valuemax'].to_i == available_height
              sleep 0.05
            end
          end

          grown_valuemax = @handle[:'aria-valuemax'].to_i
          expect(grown_valuemax).to eq(available_height)
          expect(grown_valuemax).to be > shrunk_valuemax
          expect(tree_height).to eq(before_height)
        ensure
          page.current_window.resize_to(orig_w, orig_h)
        end
      end
    end
  end
end
