# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
  describe '#render_token' do
    let(:token_options) do
      {
        uri: '/repositories/1/resources/2',
        type: 'resource',
        label: +'Test Label'
      }
    end

    it 'renders the token as a direct link without popover behavior' do
      html = helper.render_token(token_options)

      expect(html).to include('href="/resolve/readonly?uri=/repositories/1/resources/2"')
      expect(html).to include('class="token resource"')
      expect(html).not_to include('data-toggle="popover"')
    end

    it 'does not open the link in a new tab in readonly contexts' do
      html = helper.render_token(token_options)

      expect(html).not_to include('target="_blank"')
    end

    it 'opens the link in a new tab in linker contexts' do
      html = helper.render_token(**token_options, inside_linker_browse: true)

      expect(html).to include('target="_blank"')
    end

    it 'renders the token icon when an icon class is provided' do
      html = helper.render_token(**token_options, icon_class: 'icon-book')

      expect(html).to include("<span class='icon-token icon-book'></span>")
    end

    it 'renders edit mode tokens without readonly token styling' do
      html = helper.render_token(**token_options, inside_token_editor: true)

      expect(html).not_to include('class="token resource"')
    end
  end
end
