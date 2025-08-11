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

    describe 'handle' do
      it 'includes expected ARIA attributes on page load' do
        expect(@handle[:'role']).to eq('separator')
        expect(@handle[:'aria-orientation']).to eq('horizontal')
        expect(@handle[:'tabindex']).to eq('0')
        expect(@handle[:'aria-valuemin']).to eq('60')
        expect(@handle[:'aria-valuenow'].to_i).to eq(tree_height)
        expect(@handle[:'aria-valuemax'].to_i).to eq(available_height)
      end

      describe 'mouse drag' do
        it 'changes tree height and updates aria-valuenow' do
          start_height = tree_height

          drag_handle_by(100)

          new_height = tree_height
          expect(new_height).to eq(start_height + 100)
          expect(@handle[:'aria-valuenow'].to_i).to eq(new_height)

          drag_handle_by(-50)

          new_height = tree_height
          expect(new_height).to eq(start_height + 50)
          expect(@handle[:'aria-valuenow'].to_i).to eq(new_height)
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
          expect(@handle[:'aria-valuenow'].to_i).to eq(min_h)
        end

        context 'after resizing the tree' do
          before do
            drag_handle_by(80)
          end

          include_examples 'persists tree height across page visits'
        end
      end

      describe 'keyboard controls' do
        it 'Home sets to min, End sets to max' do
          @handle.send_keys(:home)
          expect(@handle[:'aria-valuenow'].to_i).to eq(@handle[:'aria-valuemin'].to_i)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)

          @handle.send_keys(:end)
          expect(@handle[:'aria-valuenow'].to_i).to eq(@handle[:'aria-valuemax'].to_i)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)
        end

        it 'ArrowUp/Right increase by step; ArrowDown/Left decrease by step' do
          step = 10
          start = @handle[:'aria-valuenow'].to_i

          @handle.send_keys(:arrow_up)
          expect(@handle[:'aria-valuenow'].to_i).to eq(start + step)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)

          @handle.send_keys(:arrow_right)
          expect(@handle[:'aria-valuenow'].to_i).to eq(start + step * 2)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)

          @handle.send_keys(:arrow_down)
          expect(@handle[:'aria-valuenow'].to_i).to eq(start + step)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)

          @handle.send_keys(:arrow_left)
          expect(@handle[:'aria-valuenow'].to_i).to eq(start)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)
        end

        it 'PageUp/PageDown adjust by large step' do
          step = 50
          start = @handle[:'aria-valuenow'].to_i

          @handle.send_keys(:page_up)
          expect(@handle[:'aria-valuenow'].to_i).to eq(start + step)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)

          @handle.send_keys(:page_down)
          expect(@handle[:'aria-valuenow'].to_i).to eq(start)
          expect(tree_height).to eq(@handle[:'aria-valuenow'].to_i)
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
            3.times do
              @handle.send_keys(:arrow_up)
            end
          end

          include_examples 'persists tree height across page visits'
        end
      end
    end

    describe 'toggle' do
      it 'includes expected ARIA attributes on page load' do
        expect(@toggle[:'aria-expanded']).to eq('false')
      end

      describe 'click' do
        it 'maximizes and minimizes the tree height, with related aria and class updates' do
          @toggle.click
          expect(tree_height).to eq(available_height)
          expect(tree_height).to eq(@handle[:'aria-valuemax'].to_i)
          expect(@handle).to match_css('.maximized')
          expect(@toggle[:'aria-expanded']).to eq('true')

          @toggle.click
          expect(tree_height).to eq(@handle[:'aria-valuemin'].to_i)
          expect(@handle).not_to match_css('.maximized')
          expect(@toggle[:'aria-expanded']).to eq('false')
        end

        context 'after resizing the tree' do
          before do
            @toggle.click
          end

          include_examples 'persists tree height across page visits'
        end
      end

      describe 'keyboard controls' do
        it 'Space and Enter maximize and minimize the tree height' do
          @toggle.send_keys(:space)
          expect(tree_height).to eq(available_height)
          expect(@handle).to match_css('.maximized')
          expect(@toggle[:'aria-expanded']).to eq('true')

          @toggle.send_keys(:enter)
          expect(tree_height).to eq(@handle[:'aria-valuemin'].to_i)
          expect(@handle).not_to match_css('.maximized')
          expect(@toggle[:'aria-expanded']).to eq('false')

          @toggle.send_keys(:enter)
          expect(tree_height).to eq(available_height)
          expect(@handle).to match_css('.maximized')
          expect(@toggle[:'aria-expanded']).to eq('true')

          @toggle.send_keys(:space)
          expect(tree_height).to eq(@handle[:'aria-valuemin'].to_i)
          expect(@handle).not_to match_css('.maximized')
          expect(@toggle[:'aria-expanded']).to eq('false')
        end

        context 'after resizing the tree' do
          before do
            @toggle.send_keys(:space)
          end

          include_examples 'persists tree height across page visits'
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
