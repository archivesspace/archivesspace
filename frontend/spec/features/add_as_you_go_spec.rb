# frozen_string_literal: true
require 'spec_helper'
require 'rails_helper'

describe 'Add As You Go buttons', js: true do
  before(:each) do
    login_admin
  end

  context 'when editing a non-Agent record type' do
    shared_examples 'and when editing a top-level non-Notes subform' do |type, num_expected_subforms, num_expected_header_buttons|
      context 'which can have zero or many subform instances' do
        it "appear in the subform footer, duplicating each button in the subform header, for #{type}s" do
          visit type != 'location_batch' ? "/#{type}s/new" : '/locations/batch'
          subforms = page.all '[data-subrecord-form="true"][data-cardinality="zero_to_many"]:not(.subrecord-form-hidden)'
          all_header_buttons = page.all '[data-subrecord-form="true"][data-cardinality="zero_to_many"] > h3 button'

          expect(subforms.count).to eq num_expected_subforms
          expect(all_header_buttons.count).to eq num_expected_header_buttons

          subforms.each do |subform|
            header_buttons = subform.all '[data-cardinality] > h3 button'
            header_buttons.first.click
            expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child', visible: false

            header_buttons.each do |button|
              subform.hover
              if header_buttons.count > 1
                expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child > a', text: button.text, visible: true
              else
                expect(subform).to have_css ".subrecord-add-as-you-go-actions:last-child > a[title='#{button.text}']", text: '+', visible: true
              end
            end
          end
        end
      end
    end

    shared_examples 'and when editing the top-level Notes subform' do |type|
      it "appear in the subform footer, duplicating each button in the subform header, for #{type}s" do
        visit "/#{type}s/new"
        subform = page.find "##{type}_notes_"
        within subform do
          click_button 'Add Note'
          expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child > a', text: 'Add Note', visible: false
          expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child > a', text: 'Apply Standard Note Order', visible: false
          subform.hover
          expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child > a', text: 'Add Note', visible: true
          expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child > a', text: 'Apply Standard Note Order', visible: true
        end
      end
    end

    shared_examples 'and when editing the nested Language Note subform' do |type|
      context 'in the top-level Languages subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type}s" do
          visit "/#{type}s/new"
          subform = page.find '[data-subrecord-form="true"][data-cardinality="zero_to_many"][data-object-name="lang_material"]'
          within subform do
            click_button 'Add Language Note'
            expect(subform).to have_css '#lang_material_notes > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
            subform.hover
            expect(subform).to have_css '#lang_material_notes > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          end
        end
      end
    end

    shared_examples 'and when editing nested subforms' do |type|
      context 'in the top-level Rights Statement subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type}s" do
          visit "/#{type}s/new"
          subform = page.find '[data-subrecord-form="true"][data-cardinality="zero_to_many"][data-object-name="rights_statement"]'
          within subform do
            click_button 'Add Rights Statement'
            within '#rights_statement_notes' do
              click_button 'Add Note'
            end
            within '[data-object-name="act"]' do
              click_button 'Add Act'
              click_button 'Add Note'
            end
            within '[data-object-name="external_document"]' do
              click_button 'Add External Document'
            end
            within '[data-object-name="linked_agent"]' do
              click_button 'Add Agent Link'
            end
          end
          expect(subform).to have_css '#rights_statement_notes > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
          expect(subform).to have_css '[data-object-name="act"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Act"]', text: '+', visible: false
          expect(subform).to have_css '[data-object-name="act"] #rights_statement_act_notes > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
          expect(subform).to have_css '[data-object-name="external_document"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add External Document"]', text: '+', visible: false
          expect(subform).to have_css '[data-object-name="linked_agent"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Agent Link"]', text: '+', visible: false
          subform.hover
          expect(subform).to have_css '#rights_statement_notes > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          expect(subform).to have_css '[data-object-name="act"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Act"]', text: '+', visible: true
          expect(subform).to have_css '[data-object-name="act"] #rights_statement_act_notes > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          expect(subform).to have_css '[data-object-name="external_document"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add External Document"]', text: '+', visible: true
          expect(subform).to have_css '[data-object-name="linked_agent"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Agent Link"]', text: '+', visible: true
        end
      end
    end

    shared_examples 'and when editing the nested Extent subform' do |type|
      context 'in the top-level Deaccession subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type}s" do
          visit "/#{type}s/new"
          subform = page.find '[data-subrecord-form="true"][data-cardinality="zero_to_many"][data-object-name="deaccession"]'
          within subform do
            click_button 'Add Deaccession'
            click_button 'Add Extent'
            expect(subform).to have_css '[data-object-name="extent"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Extent"]', text: '+', visible: false
            subform.hover
            expect(subform).to have_css '[data-object-name="extent"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Extent"]', text: '+', visible: true
          end
        end
      end
    end

    it_behaves_like 'and when editing a top-level non-Notes subform', 'accession', 14, 16
    it_behaves_like 'and when editing a top-level non-Notes subform', 'resource', 13, 15
    it_behaves_like 'and when editing a top-level non-Notes subform', 'digital_object', 10, 11
    it_behaves_like 'and when editing a top-level non-Notes subform', 'subject', 3, 3
    it_behaves_like 'and when editing a top-level non-Notes subform', 'location', 1, 1
    it_behaves_like 'and when editing a top-level non-Notes subform', 'location_batch', 1, 1
    it_behaves_like 'and when editing a top-level non-Notes subform', 'event', 3, 3
    it_behaves_like 'and when editing a top-level non-Notes subform', 'classification', 1, 1
    it_behaves_like 'and when editing a top-level non-Notes subform', 'assessment', 1, 1

    it_behaves_like 'and when editing the top-level Notes subform', 'resource'
    it_behaves_like 'and when editing the top-level Notes subform', 'digital_object'

    it_behaves_like 'and when editing the nested Language Note subform', 'accession'
    it_behaves_like 'and when editing the nested Language Note subform', 'resource'
    it_behaves_like 'and when editing the nested Language Note subform', 'digital_object'

    it_behaves_like 'and when editing nested subforms', 'accession'
    it_behaves_like 'and when editing nested subforms', 'resource'
    it_behaves_like 'and when editing nested subforms', 'digital_object'

    it_behaves_like 'and when editing the nested Extent subform', 'accession'
    it_behaves_like 'and when editing the nested Extent subform', 'resource'

    it 'do not appear when editing a Container Profile' do
      visit '/container_profiles/new'
      expect(page).to have_no_css '[data-subrecord-form="true"][data-cardinality="zero_to_many"], .subrecord-form.notes-form'
    end
  end

  context 'when editing an Agent record type' do
    shared_examples 'and when editing a top-level non-Notes subform' do |type, num_expected_subforms, num_expected_header_buttons|
      context 'which can have zero or many subform instances' do
        it "appear in the subform footer, duplicating each button in the subform header, for #{type} agents" do
          visit "/agents/agent_#{type}/new"
          uncheck 'Light Mode'
          subforms = page.all '.subrecord-form-section > [data-subrecord-form="true"][data-cardinality="zero_to_many"]:not(.subrecord-form-hidden)'
          all_header_buttons = page.all '.subrecord-form-section > [data-subrecord-form="true"][data-cardinality="zero_to_many"]:not(.subrecord-form-hidden) > h3 button'

          if type != 'software'
            # The related_agents subform is not present for software and is tested separately
            expect(subforms.count).to eq num_expected_subforms - 1
            expect(all_header_buttons.count).to eq num_expected_header_buttons - 1
          else
            expect(subforms.count).to eq num_expected_subforms
            expect(all_header_buttons.count).to eq num_expected_header_buttons
          end

          subforms.each do |subform|
            header_buttons = subform.all '[data-cardinality] > h3 button'
            header_buttons.first.click
            expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child', visible: false
            header_buttons.each do |button|
              subform.hover
              if header_buttons.count > 1
                expect(subform).to have_css '.subrecord-add-as-you-go-actions:last-child > a', text: button.text, visible: true
              else
                expect(subform).to have_css ".subrecord-add-as-you-go-actions:last-child > a[title='#{button.text}']", text: '+', visible: true
              end
            end
          end

          if type != 'software'
            related_agents_subform = page.find '#related_agents'
            within related_agents_subform do
              header_button = related_agents_subform.find '#related_agents > header > button'
              header_button.click
              expect(related_agents_subform).to have_css '.subrecord-add-as-you-go-actions:last-child', visible: false
              related_agents_subform.hover
              expect(related_agents_subform).to have_css ".subrecord-add-as-you-go-actions:last-child > a[title='#{header_button.text}']", text: '+', visible: true
            end
          end
        end
      end
    end

    shared_examples 'and when editing the top-level Notes subform' do |type|
      it "appear in the subform footer, duplicating each button in the subform header, for #{type} agents" do
        visit "/agents/agent_#{type}/new"
        subform = page.find "#agent_#{type}_notes"
        within subform do
          click_button 'Add Note'
          expect(subform).to have_css ".subrecord-add-as-you-go-actions:last-child > a[title='Add Note']", text: '+', visible: false
          subform.hover
          expect(subform).to have_css ".subrecord-add-as-you-go-actions:last-child > a[title='Add Note']", text: '+', visible: true
        end
      end
    end

    shared_examples 'and when editing nested subforms' do |type|
      before(:each) do
        visit "/agents/agent_#{type}/new"
        uncheck 'Light Mode'
      end

      context 'within the Name Forms subform' do
        it "appear in the nested subform footer, duplicating the button in the nested subform header, for #{type} agents" do
          names_subform = page.find "#agent_#{type}_names"
          within '#agent_names__0__use_dates_' do
            click_button 'Add Use Date'
          end
          within '#agent_names__0__parallel_names_' do
            click_button 'Add Parallel Name'
            click_button 'Add Use Date'
          end
          expect(names_subform).to have_css "[data-subrecord-form='true'][data-object-name='use_date']:not([id*='parallel_names']) > .subrecord-add-as-you-go-actions:last-child > a[title='Add Use Date']", text: '+', visible: false
          expect(names_subform).to have_css "[data-subrecord-form='true'][data-object-name='use_date'][id*='parallel_names'] > .subrecord-add-as-you-go-actions:last-child > a[title='Add Use Date']", text: '+', visible: false
          expect(names_subform).to have_css "[data-subrecord-form='true'][data-object-name='parallel_name'] > .subrecord-add-as-you-go-actions:last-child > a[title='Add Parallel Name']", text: '+', visible: false
          names_subform.hover
          expect(names_subform).to have_css "[data-subrecord-form='true'][data-object-name='use_date']:not([id*='parallel_names']) > .subrecord-add-as-you-go-actions:last-child > a[title='Add Use Date']", text: '+', visible: true
          expect(names_subform).to have_css "[data-subrecord-form='true'][data-object-name='use_date'][id*='parallel_names'] > .subrecord-add-as-you-go-actions:last-child > a[title='Add Use Date']", text: '+', visible: true
          expect(names_subform).to have_css "[data-subrecord-form='true'][data-object-name='parallel_name'] > .subrecord-add-as-you-go-actions:last-child > a[title='Add Parallel Name']", text: '+', visible: true
        end
      end

      if type == 'person'
        context 'within the Genders subform' do
          it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
            genders_subform = page.find '#agent_person_agent_gender'
            within genders_subform do
              click_button 'Add Gender'
              click_button 'Add Date'
              click_button 'Add Note'
            end
            expect(genders_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: false
            expect(genders_subform).to have_css '#agent_gender.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
            genders_subform.hover
            expect(genders_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: true
            expect(genders_subform).to have_css '#agent_gender.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          end
        end
      end

      context 'within the Places subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
          places_subform = page.find "#agent_#{type}_agent_place"
          within places_subform do
            click_button 'Add Place'
            click_button 'Add Subject'
            click_button 'Add Note'
            click_button 'Add Date'
          end
          expect(places_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: false
          expect(places_subform).to have_css '#agent_place.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
          expect(places_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: false
          places_subform.hover
          expect(places_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: true
          expect(places_subform).to have_css '#agent_place.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          expect(places_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: true
        end
      end

      context 'within the Occupations subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
          occupations_subform = page.find "#agent_#{type}_agent_occupation"
          within occupations_subform do
            click_button 'Add Occupation'
            click_button 'Add Subject'
            click_button 'Add Place'
            click_button 'Add Note'
            click_button 'Add Date'
          end
          expect(occupations_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: false
          expect(occupations_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: false
          expect(occupations_subform).to have_css '#agent_occupation.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
          expect(occupations_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: false
          occupations_subform.hover
          expect(occupations_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: true
          expect(occupations_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: true
          expect(occupations_subform).to have_css '#agent_occupation.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          expect(occupations_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: true
        end
      end

      context 'within the Functions subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
          functions_subform = page.find "#agent_#{type}_agent_function"
          within functions_subform do
            click_button 'Add Function'
            click_button 'Add Subject'
            click_button 'Add Place'
            click_button 'Add Note'
            click_button 'Add Date'
          end
          expect(functions_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: false
          expect(functions_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: false
          expect(functions_subform).to have_css '#agent_function.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
          expect(functions_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: false
          functions_subform.hover
          expect(functions_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: true
          expect(functions_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: true
          expect(functions_subform).to have_css '#agent_function.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          expect(functions_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: true
        end
      end

      context 'within the Topics subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
          topics_subform = page.find "#agent_#{type}_agent_topic"
          within topics_subform do
            click_button 'Add Topic'
            click_button 'Add Subject'
            click_button 'Add Place'
            click_button 'Add Note'
            click_button 'Add Date'
          end
          expect(topics_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: false
          expect(topics_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: false
          expect(topics_subform).to have_css '#agent_topic.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
          expect(topics_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: false
          topics_subform.hover
          expect(topics_subform).to have_css '[data-object-name="subject"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Subject"]', text: '+', visible: true
          expect(topics_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: true
          expect(topics_subform).to have_css '#agent_topic.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
          expect(topics_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: true
        end
      end

      context 'within the Languages Used subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
          languages_subform = page.find "#agent_#{type}_used_language"
          within languages_subform do
            click_button 'Add Language'
            click_button 'Add Note'
          end
          expect(languages_subform).to have_css '#used_language.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: false
          languages_subform.hover
          expect(languages_subform).to have_css '#used_language.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Note"]', text: '+', visible: true
        end
      end

      context 'within the Contact Details subform' do
        it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
          contact_details_subform = page.find "#agent_#{type}_contact_details"
          within contact_details_subform do
            click_button 'Add Contact'
            click_button 'Add Telephone Number'
            click_button 'Add Contact Note'
          end
          expect(contact_details_subform).to have_css '[data-object-name="telephone"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Telephone Number"]', text: '+', visible: false
          expect(contact_details_subform).to have_css '#agent_contact_notes.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Contact Note"]', text: '+', visible: false
          contact_details_subform.hover
          expect(contact_details_subform).to have_css '[data-object-name="telephone"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Telephone Number"]', text: '+', visible: true
          expect(contact_details_subform).to have_css '#agent_contact_notes.notes-form > .subrecord-add-as-you-go-actions:last-child > a[title="Add Contact Note"]', text: '+', visible: true
        end
      end

      unless type == 'software'
        context 'within the Related External Resources subform' do
          it "appear in the nested subform footer, duplicating each button in the nested subform header, for #{type} agents" do
            related_agents_subform = page.find "#agent_#{type}_agent_resource"
            within related_agents_subform do
              click_button 'Add Related External Resource'
              click_button 'Add Place'
              click_button 'Add Date'
            end
            expect(related_agents_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: false
            expect(related_agents_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: false
            related_agents_subform.hover
            expect(related_agents_subform).to have_css '[data-object-name="place"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Place"]', text: '+', visible: true
            expect(related_agents_subform).to have_css '[data-object-name="date"] > .subrecord-add-as-you-go-actions:last-child > a[title="Add Date"]', text: '+', visible: true
          end
        end
      end
    end

    it_behaves_like 'and when editing a top-level non-Notes subform', 'person', 20, 20
    it_behaves_like 'and when editing a top-level non-Notes subform', 'family', 19, 19
    it_behaves_like 'and when editing a top-level non-Notes subform', 'corporate_entity', 19, 19
    it_behaves_like 'and when editing a top-level non-Notes subform', 'software', 10, 10

    it_behaves_like 'and when editing the top-level Notes subform', 'person'
    it_behaves_like 'and when editing the top-level Notes subform', 'family'
    it_behaves_like 'and when editing the top-level Notes subform', 'corporate_entity'
    it_behaves_like 'and when editing the top-level Notes subform', 'software'

    it_behaves_like 'and when editing nested subforms', 'person'
    it_behaves_like 'and when editing nested subforms', 'family'
    it_behaves_like 'and when editing nested subforms', 'corporate_entity'
    it_behaves_like 'and when editing nested subforms', 'software'
  end
end
