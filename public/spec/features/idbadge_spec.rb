require 'spec_helper'
require 'rails_helper'

describe 'ID Badge component', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "idbadge_test_#{Time.now.to_i}")
    set_repo(@repo)

    @accession = create(:accession,
      title: 'This is a <title>mixed content</title> accession',
      publish: true
    )

    @subject = create(:subject,
      terms: [build(:term, {term: "This is a <title>mixed content</title> subject", term_type: 'temporal'})]
    )

    @resource = create(:resource,
      title: 'This is a <title>mixed content</title> resource',
      publish: true,
      subjects: [{'ref' => @subject.uri}]
    )

    @ao = create(:archival_object,
      resource: {'ref' => @resource.uri},
      title: 'This is a <title>mixed content</title> archival object',
      publish: true
    )

    @do = create(:digital_object,
      title: 'This is a <title>mixed content</title> digital object',
      publish: true
    )

    @doc = create(:digital_object_component,
      digital_object: { ref: @do.uri },
      title: 'This is a <title>mixed content</title> digital object component',
      publish: true
    )

    run_indexers
  end

  context 'when displaying mixed content in titles' do
    shared_examples 'a mixed content title' do |record_var|
      let(:record_type_names) do
        {
          '@ao' => 'archival object',
          '@do' => 'digital object',
          '@doc' => 'digital object component'
        }
      end

      it 'displays the full title with properly rendered mixed content' do
        visit instance_variable_get(record_var).uri
        idbadge_title = find('#info_row h1')
        record_name = record_type_names[record_var.to_s] || record_var.to_s.delete('@')
        expect(idbadge_title).to have_content("This is a mixed content #{record_name}")
        expect(idbadge_title).to have_css('span.title', text: 'mixed content')
      end
    end

    it_behaves_like 'a mixed content title', :@accession
    it_behaves_like 'a mixed content title', :@resource
    it_behaves_like 'a mixed content title', :@ao
    it_behaves_like 'a mixed content title', :@do
    it_behaves_like 'a mixed content title', :@doc
    it_behaves_like 'a mixed content title', :@subject
  end
end
