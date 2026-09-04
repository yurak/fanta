require 'rails_helper'

RSpec.describe Scores::ScrapeAlert do
  before { allow(Rollbar).to receive(:warning) }

  it 'warns when scrapes are failing (health) and none returned data' do
    described_class.call(candidates: 3, with_data: 0, failures: 3, tournaments: ['England'])

    expect(Rollbar).to have_received(:warning).with(%r{3/3 live matches}, hash_including(candidates: 3, tournaments: ['England']))
  end

  it 'warns on a partial outage where most matches fail' do
    described_class.call(candidates: 4, with_data: 1, failures: 3, tournaments: ['England'])

    expect(Rollbar).to have_received(:warning).with(%r{3/4 live matches}, hash_including(failures: 3))
  end

  it 'does not warn when only a minority of matches fail' do
    described_class.call(candidates: 5, with_data: 4, failures: 1, tournaments: ['England'])

    expect(Rollbar).not_to have_received(:warning)
  end

  it 'does not warn when the only misses were bad page_urls (no health failures)' do
    described_class.call(candidates: 2, with_data: 0, failures: 0, tournaments: ['England'])

    expect(Rollbar).not_to have_received(:warning)
  end

  it 'does not warn when there were no candidates' do
    described_class.call(candidates: 0, with_data: 0, failures: 0, tournaments: [])

    expect(Rollbar).not_to have_received(:warning)
  end
end
