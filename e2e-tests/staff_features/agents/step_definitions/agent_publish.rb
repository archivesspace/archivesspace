# frozen_string_literal: true

Then 'the Agent opens on a new tab in the public interface' do
  expect(page.windows.size).to eq 2
  switch_to_window(page.windows[1])

  tries = 0

  while current_url == 'about:blank'
    break if tries == 3

    tries += 1
    sleep 1
  end

  expect(current_url).to eq "#{PUBLIC_URL}/agents/people/#{@agent_id}"
end

Given 'the Agent is published' do
  expect(find('#agent_publish_').checked?).to eq true
end
