require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization Load All with a JSON error response', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "load_all_json_error_test_#{Time.now.to_i}")
    set_repo(@repo)

    # Test config: waypoint size 5, main thread max 3 concurrent fetches
    @res_5wp = create(:resource, title: 'Load All JSON error, 5 waypoints', publish: true)
    batch_create_archival_objects(20, resource: @res_5wp) { |i| { title: "AO #{i + 1}" } }

    @res_10wp = create(:resource, title: 'Load All JSON error, 10 waypoints', publish: true)
    batch_create_archival_objects(45, resource: @res_10wp) { |i| { title: "AO #{i + 1}" } }

    run_indexers
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
  end

  # Wait for the initial waypoints, then make every later waypoints request
  # return a JSON error body with a 429, as a rate-limiting proxy might
  def visit_and_fail_later_waypoint_requests(resource)
    visit "/repositories/#{@repo.id}/resources/#{resource.id}/collection_organization"

    aggregate_failures do
      expect(page).to have_css('#infinite-records-container .waypoint.populated[data-waypoint-number="0"]')
      expect(page).to have_css('#infinite-records-container .waypoint.populated[data-waypoint-number="1"]')
      expect(page).not_to have_css('#records-loading-dialog[open]', visible: :all)
    end

    allow_any_instance_of(ResourcesController).to receive(:waypoints) do |controller|
      controller.render json: { error: 'Too Many Requests' }, status: 429
    end
  end

  def expect_no_undefined_records_after_load_all
    # Waypoint 2 may have loaded on its own before the stub, so note which
    # waypoints are populated when Load All starts
    populated_before = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#infinite-records-container .waypoint.populated'))
        .map(wp => wp.dataset.waypointNumber)
    JS

    # There is no dialog 'open' event, so mark the page when it closes
    page.execute_script(<<~JS)
      document.querySelector('#records-loading-dialog').addEventListener('close', () => {
        document.body.dataset.loadAllDialogClosed = 'true';
      }, { once: true });
    JS

    page.find('.load-all__label-toggle').click

    aggregate_failures do
      expect(page).to have_css('body[data-load-all-dialog-closed]')
      expect(page).not_to have_css(
        '#infinite-records-container .infinite-record-record',
        exact_text: 'undefined',
        visible: :all
      )
    end

    # Waypoints whose fetch failed should stay empty so they can be fetched again
    populated_after = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#infinite-records-container .waypoint.populated'))
        .map(wp => wp.dataset.waypointNumber)
    JS
    expect(populated_after).to match_array(populated_before)
  end

  context 'when the remaining waypoints load on the main thread' do
    it 'does not render "undefined" records or mark failed waypoints populated' do
      visit_and_fail_later_waypoint_requests(@res_5wp)
      expect_no_undefined_records_after_load_all
    end
  end

  context 'when the remaining waypoints load in the web worker' do
    it 'does not render "undefined" records or mark failed waypoints populated' do
      visit_and_fail_later_waypoint_requests(@res_10wp)
      expect_no_undefined_records_after_load_all
      expect(page).to have_css('#load-all-error', visible: true)
    end
  end
end
