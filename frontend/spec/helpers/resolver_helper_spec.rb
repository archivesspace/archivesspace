# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ResolverHelper do
  let(:url) { '/repositories/2/resources/1' }
  let(:label) { 'A Test Link' }

  describe '#resolve_readonly_link_to' do

    it 'generates a readonly link' do
      link = resolve_readonly_link_to(label, url)

      expect(link).to have_link(label,
                                href: '/resolve/readonly?uri=%2Frepositories%2F2%2Fresources%2F1')
    end

    it 'does not generate a link if active is false' do
      inactive_link = resolve_readonly_link_to(label, url, false)

      expect(inactive_link).not_to have_link(label)
      expect(inactive_link).to have_text(label)
    end
  end

  describe '#resolve_edit_link_to' do

    it 'generates an edit link' do
      link = resolve_edit_link_to(label, url)
      expect(link).to have_link(label,
                                href: '/resolve/edit?uri=%2Frepositories%2F2%2Fresources%2F1')
    end
  end
end
