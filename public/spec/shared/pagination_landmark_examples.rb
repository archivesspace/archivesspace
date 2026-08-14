# frozen_string_literal: true

RSpec.shared_examples 'having two distinct pagination landmarks' do
  it 'labels top and bottom pagination navs uniquely' do
    visit pagination_path
    finished_all_ajax_requests?

    top_label = I18n.t('pagination.top_controls')
    bottom_label = I18n.t('pagination.bottom_controls')

    aggregate_failures 'pagination landmark labels' do
      expect(page).to have_css("nav#paging[aria-label='#{top_label}']")
      expect(page).to have_css("nav#paging_bottom[aria-label='#{bottom_label}']")
    end
  end
end

RSpec.shared_examples 'having one pagination landmark' do
  it 'renders one pagination nav with a generic label' do
    visit pagination_path
    finished_all_ajax_requests?

    controls_label = I18n.t('pagination.controls')

    aggregate_failures 'pagination landmark labels' do
      expect(page).to have_css("nav#paging[aria-label='#{controls_label}']", count: 1)
      expect(page).not_to have_css('nav#paging_bottom')
    end
  end
end
